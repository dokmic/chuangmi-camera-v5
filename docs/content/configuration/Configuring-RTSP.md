# Configuring RTSP

## Enabling the RTSP daemon

**WARNING: The RTSP daemon has authentication but without encryption! 
Read the [Security Considerations](/Security-Considerations) for more information**

By default, the rtspd is enabled. You can disable it by setting `RTSP` to `0` and stop the rtspd service
on the commandline by executing the init script, or through the services page in the web interface.

If enabled the RTSP server is listening on port `554`.

You can connect to live video stream (currently only supports 720p) on:
```
rtsp://your-camera-ip/live/ch00_0
```

**For stability reasons disable cloud services while using RTSP.**

## Authentication

Since `v0.959` the rtsp stream uses authentication to keep unwanted viewers from watching you in your underpants.

Set the `RTSP_USER` and `RTSP_PASSWORD` to something you can remember.

To completely disable the authentication, set the variables to `RTSP_PASSWORD=` and `RTSP_USER=` (to an empty string).

## Changing settings of the RTSP stream

You can change several settings of the RTSP daemon within the limits of the camera.

If you want to change the frame-rate (FPS) settings, 
test for the best possible results as not all settings changes work out well. 
You can change the frame-rate to above 15fps, but effectively it will not go much higher than 20 frames per second.

The camera is very picky about some settings. 
If the camera stream seems glitchy or the camera is periodically rebooting, 
change the RTSP settings in `config.cfg` back to its default.


## Recommended settings

During tests the quality and overall performance of the camera was at best using a variable bitrate, 
as the camera can skip some frames when it's under stress.

Using the `GM_EVBR` mode or `GM_VBR` does not seem to make much difference but try for yourself 
if you experience issues with the settings you are using.

The recommended settings for best performance and quality are:

| Encoding | Bitrate Mode   | (Max) Bitrate | FPS  | Width | Height |
| ----     | ----           | ----          | ---- | ----  | ----   |
| `H264`   | `GM_EVBR` (`4`)| 8192          | 15   | 1280  | 720    |
| `MPEG4`  | `GM_EVBR` (`4`)| 2048          | 10   | 1280  | 720    |
| `MJPEG`  | `GM_CBR`  (`1`)| 4096          | 15   | 1280  | 720    |

**When there is low light and the camera has lots of data to process, for example when the images are rapidly changing, 
using a bitrate that is too high for the camera can result in a crashing or glitchy rtsp stream. 
If this happens, try lowering the max bitrate (IE: from 8092 to 4096 or lower).**

**Since v0.961 the rtspd service allows setting a higher frame-rate than 15 fps. 
This increases power usage and may cause instability of the camera.**

## Available Bitrate Modes

The available bitrate modes are:

| Bitrate Mode | Bitrate Mode Variable | Description
| ----         | ----                  | ----
| 1            | `GM_CBR` 	           | [Constant Bitrate](https://en.wikipedia.org/wiki/Constant_bitrate).
| 2            | `GM_VBR`              | [Variable Bitrate](https://en.wikipedia.org/wiki/Variable_bitrate).
| 3            | `GM_ECBR`             | Enhanced Constant Bitrate.
| 4            | `GM_EVBR`             | Enhanced Variable Bitrate.

## Encoder type option of the rtspd binary.

The RTSP service supports multiple encoder types.
These settings are accepted as command line arguments of the `rtspd` binary.

As `H264` gives the best results in performance and image quality, this is the recommended and default encoding used.
You can use `Mjpeg` and `mpeg4` as well, by adding the RTSP_MJPEG or RTSP_MPEG4 variables accordingly in `config.cfg`.

## Configuration options

### RTSP Settings

The options for the RTSP service are:

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `RTSP`                   | `1` to enable, `0` to disable. | Enable or disable the rtspd service |
| `RTSP_USER`              | The username string to connect | Set to enable password authentication |
| `RTSP_PASSWORD`          | The password string to connect | Set to enable password authentication |
| `RTSP_WIDTH`             | An integer below `1280`        | Set the image width of the rtsp stream |
| `RTSP_HEIGHT`            | An integer below `720`         | Set the image height of the rtsp stream |
| `RTSP_FRAMERATE`         | An integer below `15`          | Set the max fps of the rtsp stream |
| `RTSP_BITRATE`           | An integer below `8192`        | Set the max bitrate of the rtsp stream |
| `RTSP_BITRATE_MODE`      | An integer between `0` and `4` | Set the bitrate mode of the rtsp stream |
| `RTSP_MOTION_DETECTION`  | `1` to enable, `0` to disable  | Enable motion detection |
| `RTSP_MJPEG`             | `1` to enable, `0` to disable  | Enable MJPEG encoding |
| `RTSP_MPEG4`             | `1` to enable, `0` to disable  | Enable MPEG4 encoding |
