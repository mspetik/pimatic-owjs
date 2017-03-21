pimatic-owjs-plugin
=======================
This plugin basic for [Pimatic](http://pimatic.org)

Install
-------
You  install owserver
```sh
sudo apt-get install owserver ow-shell
```
Edit file /etc/owfs.conf and change lines

 `server: port = localhost:4304`
 
to access only from localhost

 `server: port = 127.0.0.0:4304`
 
or access from all addresses

 `server: port = 0.0.0.0:4304`

Configuration
-------------

    { 
       "plugin": "owjs"
    }



### OwjsSwitch Device
		
Tested with device DS2405,DS2406,DS2408

    {
      "address": "12.54F81BE8E78D",      "pio": "A",
      "id": "onewire-switch",
      "name": "onewire switch",
      "class": "OwjsSwitch",
      "interval": 2500
    }

### OwjsSensor Device

Tested with device DS18B20

    {
      "address": "28.54F81BE8E78D",
      "pio": "fasttemp",
      "attributeName": "temperature",
      "id": "owjs-one-sensor",
      "name": "onewire sensor",
      "class": "OwjsSensor"
    }

### OwjsPresenceSensor Device

Tested with device DS2405,DS2406,DS2408

    {
      "address": "12.54F81BE8E78D",
      "pio": "B",
      "id": "onewire-presence",
      "name": "onewire presence",
      "class": "OwjsPresenceSensor"
    }

For device configuration options see the [device-config-schema](device-config-schema.coffee) file.
