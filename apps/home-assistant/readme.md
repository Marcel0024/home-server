
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
