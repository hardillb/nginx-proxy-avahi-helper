# nginx-proxy-avahi-helper

A docker container to generate mDNS CNAME entries for the virtual hosts
used by [jwilder/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy).

The virtual hosts are held in the VIRTUAL_HOST Env Var of the proxied container.


## Installing

`docker pull hardillb/nginx-proxy-avahi-helper`

Currently there are AMD64 and  ARM64 based builds.

## Running

To work this needs the following 2 volumes mounting:


` -v /var/run/docker.sock:/tmp/docker.sock`

This allows the container to monitor docker

` -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket`

And this allows the container to send d-bus commands to the host OS's Avahi daemon

`docker run -d -v /var/run/docker.sock:/tmp/docker.sock -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket hardillb/nginx-proxy-avahi-helper`

## AppArmor

If you are running on system with AppArmor installed you may get errors about not being able to send d-bus messages. To fix this add
`--priviledged` to the command line.

This is a temp workaround until I can work out a suitable policy to apply.
