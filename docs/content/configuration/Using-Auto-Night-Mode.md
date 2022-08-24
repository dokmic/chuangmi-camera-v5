# Using Auto Night Mode

## Auto night mode

Auto night mode is a little daemon that turns on the IR led and/or the night mode
when a certain minimum IR or light value has been reached.

## Configuration Options

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `NIGHT_MODE`             | `1` to enable, `0` to disable, or `AUTO` to control automatically. | Enable or disable the auto nightmode service (no auth) |
| `NIGHT_MODE_DELAY`       | | Delay in seconds between checks. |
| `NIGHT_MODE_EV_ON`       | | Lowest EV value. |
| `NIGHT_MODE_EV_OFF`      | | Highest EV value. |
| `NIGHT_MODE_IR_ON`       | | Lowest IR value. |
| `NIGHT_MODE_IR_OFF`      | | Highest IR value. |

## Use the old, original nightmode switcher

You can still use the previous, original nightmode switcher by changing `night-mode` to `/usr/sbin/ir_sample` in the init script.
