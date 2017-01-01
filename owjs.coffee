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
      return owclient.read('/uncached/'+@address+'/PIO.'+@pio).then( (value) =>
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
        )

    turnOn: ->
      owclient.write('/'+@address+'/PIO.'+@pio, if @inverted then 0 else 1).then( () =>
          @_setState(on)
        )

    turnOff: ->
      owclient.write('/'+@address+'/PIO.'+@pio, if @inverted then 1 else 0).then( () =>
          @_setState(off)
        )

    
    changeStateTo:  ->
      owclient.read('/'+@address+'/PIO.'+@pio).then( (value) =>
        state = (if value.value.trim() is "1" then on else off)
        if @inverted and state is on then state = off
        if @inverted and state is off then state = on
        
        owclient.write('/'+@address+'/PIO.'+@pio, if state then 0 else 1).then( () =>
          @_setState(state)
        )
      )
  class OwjsPresenceSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id
      @address = @config.address
      @pio = @config.pio
      @inverted = @config.inverted

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
      return owclient.read('/'+@address+'/sensed.'+@pio).then( (value) =>
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
      )

  class OwjsSensor extends env.devices.Sensor

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id
      @address = @config.address
      @pio = @config.pio
      
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
      return owclient.read('/'+@address+'/'+@pio).then( (value) =>
        @attributeValue = value.value.trim()
      
        if @config.attributeType is "number" then @attributeValue = parseFloat(@attributeValue)
        @emit @config.attributeName, @attributeValue
        return @attributeValue
      )
  
  # ###Finally
  # Create a instance of my plugin
  owjsPlugin = new Owjs()
  # and return it to the framework.
  return owjsPlugin
