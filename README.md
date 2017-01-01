pimatic-owjs-plugin
=======================
This plugin basic for [Pimatic](http://pimatic.org)

Install
-------
You  install and config /etc/owfs.conf
```bash
sudo apt-get install owserver ow-shell
```
Configuration
-------------

    { 
       "plugin": "owjs"
    }



### OwjsSwitch Device

    {
      "address": "12.54F81BE8E78D",
      "pio": "A",
      "id": "onewire-switch",
      "name": "onewire switch",
      "class": "OwjsSwitch",
      "interval": 2500
    }

### OwjsSensor Device

    {
      "address": "28.54F81BE8E78D",
      "pio": "fasttemp",
      "attributeName": "temperature",
      "id": "owjs-one-sensor",
      "name": "onewire sensor",
      "class": "OwjsSensor"
    }

### OwjsPresenceSensor Device

    {
      "address": "12.54F81BE8E78D",
      "pio": "B",
      "id": "onewire-presence",
      "name": "onewire presence",
      "class": "OwjsPresenceSensor"
    }

For device configuration options see the [device-config-schema](device-config-schema.coffee) file.
