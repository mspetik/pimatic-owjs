module.exports = {
  title: "owjs config options"
  type: "object"
  properties:
    host:
      description: "IP address or hostname of owserver"
      type: "string"
      required: yes
      default: "127.0.0.1"
    port:
      description: "Port of the owserver"
      type: "number"
      default: 4304
      required: yes

}
