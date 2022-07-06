# System Logging and Log files

Using the `ENABLE_LOGGING` setting in `config.cfg` you can enable and disable the kernel logging and syslog daemons.

### Logging Configuration Settings

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `ENABLE_LOGGING`         | `1` to enable, `0` to disable. | Enable klogd and syslogd |

## Kernel logging

By default, if syslogging is enabled, the kernel log daemon is enabled as well, logging kernel messages to syslog.




