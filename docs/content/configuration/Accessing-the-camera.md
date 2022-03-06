# Accessing the camera

The camera can be accessed using Telnet. (When enabled)

## Using the Telnet server

**The telnet protocol is unencrypted and therefore insecure. 
Only use it when needed, but disable the service after usage and stick to SSH for general access of the camera**

If the telnet service is enabled it is listening on port 23.


## Configuration options for Telnet

| Configuration            | Options                        | Description |
| ---                      | ---                            | ---         |
| `ENABLE_TELNETD`         | `1` to enable, `0` to disable. | Enable or disable the telnet daemon |


## Authentication issues

If boot issues appear due to syntax errors in scripts, the root password is often not set, resulting in an unauthenticated telnet service. Check your logs to find the culprit.

## Enabling the telnet service

The telnet service can be enabled at boot time by setting `ENABLE_TELNETD` to `1` in `config.cfg`.
