# Setting up motion detection

Using the RTSP service, motion detection can be enabled to send MQTT messages when movement is detected in the image stream.

## Configuration Options

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `MOTION_DETECTION`       | `1` to enable, `0` to disable  | Enable motion detection |
| `MOTION_MQTT_ON`         | A string, int or bool          | The string to send when motion is detected |
| `MOTION_MQTT_OFF`        | A string, int or bool          | The string to send when no motion detected anymore |

## Configuration example

```bash
## Enable motion detection
MOTION_DETECTION=1

## What to publish over MQTT when motion is detected
## Set ENABLE_MQTT=1 to enable
MOTION_MQTT_ON="ON"
MOTION_MQTT_OFF="OFF"

## Which topic to publish to
MOTION_TOPIC="$MQTT_TOPIC/motion"
```
