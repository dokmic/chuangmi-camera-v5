# Configuration file options

There are many options in the configuration file. As not all have their own documentation page, 
this page contains a list of some options, a description and sometimes links to other documentation pages.

## Manage Xiaomi functionality

| Configuration   | Options                        | Description |
| ---             | ---                            | ---     |
| `ENABLE_CLOUD`  | `1` to enable, `0` to disable. | Control all xiaomi functionality including the cloud streaming, audio, record on motion detection and firmware updates. |
| `ENABLE_OTA`   | `1` to enable, `0` to disable. | Control firmware updates of the official firmware. |

## System Settings

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `HOSTNAME`               | The hostname string            | The hostname of the camera
| `ROOT_PASSWORD`          | The root password string       | The root pass (used for SSH, telnet, samba and http)

## Wifi Settings

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `WIFI_PASSWORD`              | The wifi password string       | The WIFI Password. Will be saved in nvram, so can be cleared for privacy purposes. |
| `WIFI_SSID`              | The wifi SSID string           | The WIFI SSID. Will be saved in nvram at boot, so can be cleared after first boot. |


## Services

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `NIGHT_MODE`             | `1` to enable, `0` to disable, or `AUTO` to control automatically. | Enable or disable the automatic night mode daemon |


### Camera Options

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `CEILING_MODE`           | `1` to enable, `0` to disable. | Enable ceiling rotation |


See more info the [camera options page](/Camera-Options)
