
This setup using a Conbee II.

Once started make sure `./zigbee2mqtt-data/configuration.yml` has

```yaml
mqtt:
  ...
  server: mqtt://mosquitto
serial:
  ...
  adapter: deconz
```

Conbee II is setup with this configuration:

https://github.com/Koenkk/zigbee2mqtt/issues/9554#issuecomment-1866133354


Edit configuration.yaml easily, first copy it locally:

`sudo docker cp homeassistant:/config/configuration.yaml .`

Send it back:
`sudo docker cp configuration.yaml homeassistant:/config/configuration.yaml`
