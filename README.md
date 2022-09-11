# Chuangmi Camera V5 Extended Firmware
[![Build](https://github.com/dokmic/chuangmi-camera-v5/actions/workflows/build.yaml/badge.svg?branch=master)](https://github.com/dokmic/chuangmi-camera-v5/actions/workflows/tests.yaml)
[![Version](https://img.shields.io/github/v/release/dokmic/chuangmi-camera-v5?label=version)](https://github.com/dokmic/chuangmi-camera-v5/releases/latest)
[![License][license-image]][license]

This is a complimentary firmware for Chuangmi 720p Camera ([chuangmi.camera.v5](https://home.miot-spec.com/s/chuangmi.camera.v5)).
It brings an MQTT client and an alternative RTSP server that enables integration with Homebridge and Home Assistant.

Unlike others, it works with the latest official firmware and stays functional after OTA updates.

## Features
- MQTT Client.
- RTSP Server.
- Telnet Server.
- No SD-card required.
- ~60KB compressed.

## Installation
An SD card is needed to install the firmware. First, it should be formatted in FAT32.
```bash
sudo diskutil eraseDisk FAT32 CAMERA MBRFormat /dev/diskN
```

Then, download and extract the latest distribution.
```bash
wget -q -O - https://github.com/dokmic/chuangmi-camera-v5/releases/latest/download/firmware.tgz | tar -xz -C /Volumes/CAMERA
```

The distribution contains the official firmware recovery of version `3.3.6_2018062014` (`tf_recovery.img`), which will be flashed first.
To proceed, unplug and plug the power cable back. Wait until the indicator led turns blue.

At this moment, the SD card is no longer needed.
It can be safely removed after powering off the camera.
All the files on the memory card should have been renamed to the ones with the `.bak` extension.

If it has not been done already, the camera can be activated and added to the Mi Home app following the official instructions.

Then, the camera can be upgraded to the latest firmware through the device settings in Mi Home. The firmware was tested against the latest version available in the EU region (`3.4.5_2018091817`).

## Configuration
The camera can be configured via the MQTT client or manually via a config file.

In the case of the MQTT client, all the changes will be preserved in memory and restored after reboot.

When the config file is used, all the settings will be read and stored in memory.
After that, the config file will be renamed to `config.cfg.bak` to avoid overriding updated settings after reboot.

To manually configure the camera, create `config.cfg` in the SD-card root.
This file will be sourced by the firmware's init script and should set configuration variables:
```sh
MQTT=1
MQTT_HOST="192.168.1.1"
```

## Settings
Option | Type | Default | Description
--- | --- | --- | ---
`CEILING` | `0` / `1` | `0` | Rotates image when the camera is mounted on the ceil.
`CLOUD` | `0` / `1` | `1` | Cloud services that make camera appear in the Mi Home app.
`HOSTNAME` | `string` | MAC-address | The camera's hostname.
`INDICATOR` | `0` / `1` | `1` | Blue LED indicator.
`LOGGING` | `0` / `1` | `0` | Enables syslog (the log file will be stored in memory under `/var/log/messages`).
`MQTT` | `0` / `1` | `0` | MQTT client.
`MQTT_DISCOVERY_NAME` | `string` | `'Camera ${MQTT_NAME}'` | Human readable name that will appear in the Home Assistant.
`MQTT_DISCOVERY_TOPIC` | `string` | `'homeassistant'` | MQTT discovery topic [prefix](https://www.home-assistant.io/integrations/mqtt/#discovery-topic).
`MQTT_HOST` | `string` | _none_ | MQTT server host.
`MQTT_NAME` | `string` | MAC-address | Friendly name that will be used to construct MQTT topics (similar to the one in [Zigbee2MQTT](https://www.zigbee2mqtt.io/guide/configuration/devices-groups.html#common-device-options)).
`MQTT_PASSWORD` | `string` | _none_ | MQTT server password.
`MQTT_PORT` | `string` | _none_ | MQTT server port.
`MQTT_TOPIC` | `string` | `'chuangmi'` | MQTT base topic.
`MQTT_USER` | `string` | _none_ | MQTT server username.
`NIGHT` | `0` / `1` / `'AUTO'` | `0` | Night mode.
`NTP_SERVER` | `string` | `'pool.ntp.org'` | NTP server to sync time.
`OTA` | `0` / `1` | `1` | OTA services in the Mi Home app.
`PASSWORD` | `string` | _none_ | The `root`'s password.
`RTSP` | `0` / `1` | `0` | RTSP server.
`RTSP_BITRATE` | `integer` | `8192` | An integer below `8192` to set the max bitrate of the RTSP stream.
`RTSP_BITRATE_MODE` | `1` / `2` / `3` / `4` | `4` | The bitrate mode:<br> - `1` &mdash; [constant bitrate](https://en.wikipedia.org/wiki/Constant_bitrate) (`GM_CBR`);<br /> - `2` &mdash; [variable bitrate](https://en.wikipedia.org/wiki/Variable_bitrate) (`GM_VBR`);<br /> - `3` &mdash; enhanced constant bitrate (`GM_ECBR`);<br /> - `4` &mdash; enhanced variable bitrate (`GM_EVBR`).
`RTSP_FRAMERATE` | `integer` | `15` | An integer below 15 to set the max framerate (fps).
`RTSP_HEIGHT` | `integer` | `720` | Image height.
`RTSP_MJPEG` | `0` / `1` | `0` | MJPEG encoding.
`RTSP_MPEG4` | `0` / `1` | `0` | MPEG4 encoding.
`RTSP_PASSWORD` | `string` | _none_ | Password for basic authentication.
`RTSP_USER` | `string` | _none_ | Username for basic authentication.
`RTSP_WIDTH` | `integer` | `1280` | Image width.
`STREAMER` | `0` / `1` | `1` | Streaming services in the Mi Home app.
`TELNET` | `0` / `1` | `0` | Telnet server.
`TZ` | `string` | _none_ | Camera's timezone.
`WIFI_PASSWORD` | `string` | Configured in the Mi Home app. | Wireless network password.
`WIFI_SSID` | `string` | Configured in the Mi Home app. | Wireless network name.

## Usage
### RTSP
After enabling RTSP in the `config.cfg` or via MQTT, the stream can be accessed via:
```
rtsp://<host>/live/ch00_0
```

### Homebridge
The camera can be exposed via HomeKit using [Homebridge](https://homebridge.io/).
Use [`homebridge-camera-ffmpeg`](https://www.npmjs.com/package/homebridge-camera-ffmpeg) with the following config to access the camera's RTSP stream:
```json
{
  "platform": "Camera-ffmpeg",
  "cameras": [
    {
      "name": "Sample Camera",
      "manufacturer": "chuangmi",
      "model": "chuangmi.camera.v5",
      "serialNumber": "<mac>",
      "firmwareRevision": "3.4.5_2018091817",
      "videoConfig": {
        "source": "-rtsp_transport tcp -i rtsp://<host>:554/live/ch00_0",
        "stillImageSource": "-rtsp_transport tcp -i rtsp://<host>:554/live/ch00_0 -vframes 1 -r 1",
        "maxStreams": 2,
        "maxWidth": 1280,
        "maxHeight": 720,
        "maxFPS": 15,
        "videoFilter": "none",
        "vcodec": "copy"
      }
    }
  ]
}
```

### Home Assistant
Use the [FFmpeg integration](https://www.home-assistant.io/integrations/ffmpeg/) to add the camera's RTSP stream to the Home Assistant setup.

Additionally, the camera's controls can be discovered automatically using [MQTT integration](https://www.home-assistant.io/integrations/mqtt/).

## License
[WTFPL 2.0][license]

[license]: http://www.wtfpl.net/
[license-image]: https://img.shields.io/badge/license-WTFPL-blue
