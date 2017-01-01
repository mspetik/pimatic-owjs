# #Owjs device configuration options
module.exports = {
  title: "pimatic-owjs device config schemas"
  OwjsSwitch: {
    title: "OwjsSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xOnLabel", "xOffLabel"]
    properties:
      address:
        description: "The address chip [28.1234567890]"
        type: "string"
      pio:
        description: "The pio pin type DS2408 set pio 0-7 , DS2406,DS2413 set pio A,B "
        type: "string"
        enum: ["0", "1","2", "3", "4", "5", "6", "7", "A", "B"]
      inverted:
        description: "active is low?"
        type: "boolean"
        default: false
      interval:
        description: "Get state switch. 250ms is default update automaticaly"
        type: "integer"
        default: 250
  }

  OwjsPresenceSensor: {
    title: "OwjsPresenceSensor config options"
    type: "object"
    extensions: ["xPresentLabel", "xAbsentLabel"]
    properties:
      address:
        description: "The address chip [12.1234567890]"
        type: "string"
      pio:
        description: "The pio pin"
        type: "string"
        enum: ["0", "1","2", "3", "4", "5", "6", "7", "A", "B"]
      inverted:
        description: "active low?"
        type: "boolean"
        default: false
      interval:
        description: "Get state switch. 250ms is default update automaticaly"
        type: "integer"
        default: 250
  }
  OwjsSensor: {
    title: "Owjs config options"
    type: "object"
    properties:
      address:
        description: "The address chip [28.1234567890]"
        type: "string"
      pio:
        description: "The pio pin"
        type: "string"
        enum: ["fasttemp", "temperature" , "temperature12"]
      interval:
        description: "the time in ms, the command gets executed to get a new sensor value"
        type: "integer"
        default: 5000
      attributeName:
        description: "the name of the attribute the sensor is monitoring"
        type: "string"
      attributeType:
        description: "the type of the attribute the sensor is monitoring"
        type: "string"
        enum: ["string", "number"]
        default: "number"
      attributeUnit:
        description: "this unit of the attribute the sensor is monitoring"
        type: "string"
        default: ""
      attributeAcronym:
        description: "this acronym of the attribute the sensor is monitoring"
        type: "string"
        default: ""
      discrete:
        description: "
          Should be set to true if the value does not change continuously over time.
        "
        type: "boolean"
        required: false
  }
}
