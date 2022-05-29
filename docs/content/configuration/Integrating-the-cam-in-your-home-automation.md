# Integrating the cam in your home automation

As I only use one home automation suite myself (home automation), 
I can't test all the instructions to integrate the camera in your home setup of choice. 
Please let me know if the instructions are not up to date anymore.

If you use a setup that is not listed here, 
please document your configuration steps so I can add it to this article.


## Using Home assistant

To view the camera in your home assistant setup, 
use the [ffmpeg component](https://www.home-assistant.io/components/camera.ffmpeg/):

```
- platform: ffmpeg
  name: Chuangmi
  input: -rtsp_transport tcp -i rtsp://camera:554/live/ch00_0
```

## Using Home Bridge

To add this camera to homebridge then to homekit, you need HOMEBRIDGE installed somewhere (on a raspberry PI for instance)

When homebridge is configured and running, 
install the [homebridge-camera-ffmpeg](https://github.com/KhaosT/homebridge-camera-ffmpeg) plugin.

To configure the plugin, use the following json config in the platform category:

```json
{
  "platform":"Camera-ffmpeg",
  "cameras":[
     {
        "name":"Camera 1",
        "videoConfig":{
           "source":"-rtsp_transport tcp -re -i rtsp://USER:PASS@CAMERA_HOSTNAME:554/live/ch00_0",
           "stillImageSource":"-rtsp_transport tcp -re -i rtsp://USER:PASS@CAMERA_HOSTNAME:554/live/ch00_0 -vframes 1",
           "maxStreams":2,
           "maxWidth":720,
           "maxHeight":480,
           "maxFPS":15,
           "vflip":false,
           "hflip":false,
           "vcodec":"h264_omx",
           "debug": true
        }
     }
  ]
}
```

To use the snapshot, u need to manually edit the `ffmpeg.js` file of the plugin 
to modify the timeout settings used in the ffmpeg command line arguments.

Change the timeout for snapshot creation from 1s to 5s (Or alternatively, 
until this change is implemented upstream you can [use this fork](https://github.com/epalzeolithe/homebridge-camera-ffmpeg))

