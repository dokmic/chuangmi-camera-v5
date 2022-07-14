# Time settings

This hack requires NTP to be accessible for the webcam.

If you experience issues with the rtp stream or you notice a time 
in the late seventies or early eighties in your log files, make sure the camera is connected to the LAN 
and is able to reach the configured NTP server.

## Camera without internet access

To ensure your camera can set the correct time, you need to either run a local NTPd service for your local lan, 
or use the NTP proxy settings on your router if available.

To change the NTP server and timezone, edit the `config.cfg` to reflect the correct settings:

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `TZ`               | The timezone string            | The timezone to request ntp time for |
| `NTP_SERVER`             | The NTP server address string  | The ntp server to sync the time with |


```bash
############################################################
## Time Settings                                          ##
############################################################

## Set timezone
TZ="UTC"

## Prefered NTP server
NTP_SERVER="pool.ntp.org"
```

For an overview of all available timezones, 
have a look at the [timezone database](http://svn.fonosfera.org/fon-ng/trunk/luci/modules/admin-fon/root/etc/timezones.db)
