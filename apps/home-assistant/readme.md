

# Zigbee
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

# Cloudflare tunnel


Tailscale is used to access HA on laptop. On the companion app on android Cloudflare tunnel is used for remote access.

The tunnel is basically means HA is accessable from the web without port forwarding and Cloudflare is in front, meaning you can add 2fa to access HA. In this case we generate our own certificate and install that on the android device and only allow connections with that certificate.

Home Assistant Android app [doesn't support](https://github.com/home-assistant/android/issues/2650/) OAuth redirects from third parties, so we use certificates. Note Cloudflared container is used and not the HASS integration.


Guides
* [Protecting Home Assistant with Cloudflare Access and mTLS on Android](https://www.alexsilcock.net/notes/protecting-home-assistant-with-cloudflare-access-and-mtls/)
* [HA via Cloudflared with mTLS](https://gist.github.com/Fabrizz/c147c101b131c3a055057285bb3b9935)

# Edit configuration.yaml

Edit configuration.yaml easily, first copy it locally from container:

`sudo docker cp homeassistant:/config/configuration.yaml .`

Send it back:
`sudo docker cp configuration.yaml homeassistant:/config/configuration.yaml`
