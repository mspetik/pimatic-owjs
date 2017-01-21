module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  owjs = require("owjs")
  
  owclient = new (owjs.Client)(host: '127.0.0.1')
  Promise.promisifyAll(owclient)

  class Owjs extends env.plugins.Plugin

    init: (app, @framework, @config) =>
    
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("OwjsSwitch", {
        configDef: deviceConfigDef.OwjsSwitch, 
        createCallback: (config, lastState) => return new OwjsSwitch(config, lastState)
      })

      @framework.deviceManager.registerDeviceClass("OwjsPresenceSensor", {
        configDef: deviceConfigDef.OwjsPresenceSensor,
        createCallback: (config, lastState) => return new OwjsPresenceSensor(config, lastState)
      })

      @framework.deviceManager.registerDeviceClass("OwjsSensor", {
        configDef: deviceConfigDef.OwjsSensor,
        createCallback: (config, lastState) => return new OwjsSensor(config, lastState)
      })

  class OwjsSwitch extends env.devices.PowerSwitch

    constructor: (@config,@lastState) ->
      @name = @config.name
      @id = @config.id
      @address = @config.address
      @pio = @config.pio
      @inverted = @config.inverted
      @uncached = @config.uncached

      if @config.uncached then @uncached = "/uncached/" else @uncached = "/"

      @_state = lastState?.state?.value or off

      updateValue = =>
        @_updateValueTimeout = null
        @getState().finally( =>
          @_updateValueTimeout = setTimeout(updateValue, @config.interval)
        )
      
      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()

    
    getState: () ->
      return owclient.read( @uncached+@address + '/PIO.' +@pio).then( (value) =>
        owstate = value.value.trim()

        switch owstate
            when "1"
              if @inverted
                @_setState(off)
              else
                @_setState(on)
            when "0"
              if @inverted
                @_setState(on)
              else
                @_setState(off)
        ).catch( (error) =>
              env.logger.error "error read state of OWFS switch #{@name}:", error.message
              env.logger.debug error.stack
            )

    turnOn: ->
      owclient.write('/'+@address+'/PIO.'+@pio, if @inverted then 0 else 1).then( () =>
          @_setState(on)
        ).catch( (error) =>
              env.logger.error "error write state ON of OWFS switch #{@name}:", error.message
              env.logger.debug error.stack
            )

    turnOff: ->
      owclient.write('/'+@address+'/PIO.'+@pio, if @inverted then 1 else 0).then( () =>
          @_setState(off)
        ).catch( (error) =>
              env.logger.error "error write state OFF of OWFS switch #{@name}:", error.message
              env.logger.debug error.stack
            )

    
    changeStateTo:  ->
      owclient.read(@uncached+@address'/PIO.'+@pio).then( (value) =>
        state = (if value.value.trim() is "1" then on else off)
        if @inverted and state is on then state = off
        if @inverted and state is off then state = on
        
        owclient.write('/'+@address+'/PIO.'+@pio, if state then 0 else 1).then( () =>
          @_setState(state)
        ).catch( (error) =>
              env.logger.error "error change state of OWFS switch #{@name}:", error.message
              env.logger.debug error.stack
            )
      )
  class OwjsPresenceSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id
      @address = @config.address
      @pio = @config.pio
      @inverted = @config.inverted

      if @config.uncached then @uncached = "/uncached/" else @uncached = "/"

      @_presence = lastState?.presence?.value or false

      updateValue = =>
        if @config.interval > 0
          @_updateValueTimeout = null
          @getPresence().finally( =>
            @_updateValueTimeout = setTimeout(updateValue, @config.interval)
          )

      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()

    getPresence: () ->
      return owclient.read(@uncached+@address+'/sensed.'+@pio).then( (value) =>
        owstate = value.value.trim()

        switch owstate
            when "1"
              if @inverted
                @_setPresence no
              else
                @_setPresence yes
            when "0"
              if @inverted
                @_setPresence yes
              else
                @_setPresence no
      ).catch( (error) =>
              env.logger.error "error read state of OWFS presence sensor #{@name}:", error.message
              env.logger.debug error.stack
            )

  class OwjsSensor extends env.devices.Sensor

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id
      @address = @config.address
      @pio = @config.pio

      if @pio is "HIH3600" then @pio = "HIH3600/humidity"
      if @pio is "HIH4000" then @pio = "HIH4000/humidity"
      if @pio is "HTM1735" then @pio = "HTM1735/humidity"
      
      attributeName = @config.attributeName
      @attributeValue = lastState?[attributeName]?.value

      @attributes = {}
      @attributes[attributeName] =
        description: attributeName
        type: @config.attributeType

      if @config.attributeUnit.length > 0
        @attributes[attributeName].unit = @config.attributeUnit

      if @config.attributeAcronym.length > 0
        @attributes[attributeName].acronym = @config.attributeAcronym

      if @config.discrete?
        @attributes[attributeName].discrete = @config.discrete

      if @config.uncached then @uncached = "/uncached/" else @uncached = "/"

      # Create a getter for this attribute
      getter = 'get' + attributeName[0].toUpperCase() + attributeName.slice(1)
      @[getter] = () => 
        if @attributeValue? then Promise.resolve(@attributeValue) 
        else @_getUpdatedAttributeValue() 

      updateValue = =>
        if @config.interval > 0
          @_updateValueTimeout = null
          @_getUpdatedAttributeValue().finally( =>
            @_updateValueTimeout = setTimeout(updateValue, @config.interval)
          )

      super()
      updateValue()

    destroy: () ->
      clearTimeout @_updateValueTimeout if @_updateValueTimeout?
      super()

     
    _getUpdatedAttributeValue: () ->
      owclient.read( @uncached + @address + '/' +@pio ).then( (value) =>
        @attributeValue = parseFloat(value.value.trim())
        #env.logger.info "Read sensor #{@name}: #{@uncached+@address+'/'+@pio} "
        if isNaN(@attributeValue)
          owclient.read(@uncached+@address+'/'+@pio).then( (value) => #Re-reading sensor, probably outage bus
            @attributeValue = parseFloat(value.value.trim())
            #env.logger.error "second read sensor #{@name}: #{@attributeValue} "            
            if isNaN(@attributeValue)
              @attributeValue= -127 #Set sensor -127 is error value .
              env.logger.error "error get sensor #{@name} . Set value -127 (this error value) "
              @emit @config.attributeName, @attributeValue
              return @attributeValue
            else
              @emit @config.attributeName, @attributeValue
              return @attributeValue
          ).catch( (error) =>
              env.logger.error "second read is not ok #{@name}:", error.message
              env.logger.debug error.stack
            )
        else
          @emit @config.attributeName, @attributeValue
          return @attributeValue
      ).catch( (error) =>
              env.logger.error "error read value of OWFS sensor #{@name}:", error.message
              env.logger.debug error.stack
            )
  
  # ###Finally
  # Create a instance of my plugin
  owjsPlugin = new Owjs()
  # and return it to the framework.
  return owjsPlugin
