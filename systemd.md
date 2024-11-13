
# Using Z-Way with Systemd Service Manager

Using the Systemd service manager you can take advantage of some benefits, for example:
- automatic restart on failures
- an exit code/ reason
- the Systemd coredump handling

But to run Z-Way with the Systemd startup mechanism, several things 
need to be taken into account.


## The Systemd Service File

A simple working configuration file **z-way-server.service** for Z-Way:

```sh
# z-way-server.service: systemd service file

[Unit]
Description=Z-Way Server

[Service]
User=root
Group=root

Environment=PATH=/bin:/usr/bin:/sbin:/usr/sbin
WorkingDirectory=/opt/z-way-server
ExecStart=/opt/z-way-server/z-way-server
#Restart=always
#RestartSec=2min

[Install]
WantedBy=multi-user.target
```

This configuration file **z-way-server.service** 
can be installed with the script **./install_systemd.bash**.<br>
For more information on the service unit configuration refer to the 
[Systemd Website](https://systemd.io/)
and to 
[Service unit configuration](http://0pointer.de/public/systemd-man/systemd.service.html)

## Installation of the Systemd Service File

1. stop the z-way-server:<br>
   `sudo /etc/init.d/z-way-server stop`<br>
   don't delete the SysVinit script /etc/init.d/z-way-server !
2. install the Systemd service file:<br>
   `./install_systemd.bash`
3. start the z-way-server:<br>
   `sudo systemctl enable z-way-server`<br>
   `sudo systemctl start z-way-server`

## The Behavior of Z-Way

Z-Way still uses the SysVinit start-stop mechanism in init.d. 
Especially the behavior on updates has to be considered:

1. On update first it stops a running z-way-server process with<br>
    `sudo /etc/init.d/z-way-server stop`
2. During the update it creates a new SysVinit script, but only if
   there isn't one.
3. After update at last it starts the z-way-server with<br>
    `sudo /etc/init.d/z-way-server start`<br>
    Also it creates new runlevel-links for the configuration file. 

If you would migrate to Systemd and simultaneously remove the SysVinit script,
you would have to do some things manually on every update:

1. Before update:<br>
    stop the running z-way-server process
2. After the update:<br>
    stop the z-way-server again<br>
    remove the SysVinit script again<br>
    start z-way-server with the systemd command

That's inconvenient. And it could cause problems if it's forgotten.

## Systemd Manager Behavior: Coexistence of Systemd with SysVinit

If both files, the Systemd service file and the SysVinit script, are present, the
Systemd service always takes precedence and the SysVinit script is ignored, 
regardless of whether it is enabled or disabled
([Systemd FAQ](https://systemd.io/FAQ)).

My own tests have confirmed this. The z-way-server is started 
only once at system boot, although all runlevel links for init.d are existing.

Of course, this only applies to system starts and system stops, 
not to manual calls. Invoking the SysVinit commands manually won't work properly
together with Systemd.

## Changes in the SysVinit Script

To solve all the problems with concurrend execution described above, at last I came to the following
modification in my SysVinit script:

```sh

...

SYSTEMD_CONFIG=/etc/systemd/system/$NAME.service

case "$1" in
  start)
    if [ -x "$RESETFILE" ]; then
        "$RESETFILE" check_reset
    fi
    if [ -e "$SYSTEMD_CONFIG" ] 
    then
        echo "sudo systemctl start $NAME.service"
        sudo systemctl start $NAME.service
        echo "sudo systemctl enable $NAME.service"
        sudo systemctl enable $NAME.service >/dev/null 2>&1
    else
        echo -n "Starting z-way-server: "
        start-stop-daemon --start --pidfile $PIDFILE --make-pidfile --background --no-close --chdir $DAEMON_PATH --exec $NAME > /dev/null 2>&1
        echo "done."
    fi
    ;;
  stop)
    if [ -e "$SYSTEMD_CONFIG" ] 
    then
        echo "sudo systemctl disable $NAME.service"
        sudo systemctl disable $NAME.service >/dev/null 2>&1
        echo "sudo systemctl stop $NAME.service"
        sudo systemctl stop $NAME.service
    fi
    if [ `pidof $NAME` ] 
    then
        echo -n "Stopping z-way-server: "
        start-stop-daemon --stop --quiet --pidfile $PIDFILE
        rm -f $PIDFILE
        echo "done."
    fi
    ;;

...

```

If the Systemd service file doesn't exist, all SysV commands work as normal.<br>
If the Systemd service file exists, start and stop are redirected to Systemd 
commands.
An eventually declared automatic restart by Systemd is disabled after a manual stop.

This SysVinit script is stored with name **config_z-way-server.replace** and can be installed with the script 
**./install_init.d.bash**.

This change will not be removed by Z-Way. Z-Way doesn't overwrite the 
SysVinit script with the updates.

## Automatic Restart after Failure with Examination of Core Dumps

This example enhances the above described solution for
 automatic restarts after failures, with an email notification and with
 an automatic examination of core dumps.

It consists of an enhanced Systemd service file,
a bash script for the examination and a System service file for that bash script.

### The Systemd Service Files

```sh
# z-way-server.service: systemd service file

[Unit]
Description=Z-Way Server
OnFailure=exam_coredump.service

[Service]
User=root
Group=root

Environment=PATH=/bin:/usr/bin:/sbin:/usr/sbin
WorkingDirectory=/opt/z-way-server
ExecStart=/opt/z-way-server/z-way-server

Restart=on-failure
RestartSec=2min

[Install]
WantedBy=multi-user.target
```

```sh
# exam_coredump.service: systemd configuration file

[Unit]
Description=call exam_coredump.bash after Z-Way Server failure

[Service]
User=root
Group=root

Type=oneshot
Environment=PATH=/bin:/usr/bin:/sbin:/usr/sbin
WorkingDirectory=/opt/z-way-server/automation/userModules/MxSystemd/sh
ExecStart=/opt/z-way-server/automation/userModules/MxSystemd/sh/exam_coredump.bash

[Install]
WantedBy=multi-user.target

```

### Installation

1. install 2 more shell packages, necessary for the core dump examination:<br>
   `sudo apt install systemd-coredump`<br>
   `sudo apt install lz4`
2. choose the target folder where the results
   of the coredump examination shall be stored
2. create a file named **params** by copying the file **params_template** and
   enter the name of the target folder.<br>
   if you want to be notified with an email:
   create a file named **emailAccount.cfg** by copying the file 
   **emailAccount_template.cfg** and enter your data.
4. stop the z-way-server:<br>
   `sudo systemctl disable z-way-server`<br>
   `sudo systemctl stop z-way-server`
5. install the two Systemd service files:<br>
   `./install_systemd.bash z-way-server.service.restart`<br>
   `./install_systemd.bash exam_coredump.service`<br>
   `sudo systemctl enable exam_coredump.service`
6. start the z-way-server:<br>
   `sudo systemctl enable z-way-server`<br>
   `sudo systemctl start z-way-server`

Note: The result files are stored with the current timestamp and are
not removed automatically.

Note: The notification email is sent with a simple bash script. It does not
work for email services that require special authentication 
(for example like Gmail).

## Waiting for Time Synchonization

The Raspberry Pi does not have a hardware clock. Normally this is not a 
problem. However, it is ugly if the timestamps are temporarily incorrect 
after a boot (e.g. in the log file).

The following method can be used to delay the start of z-way-server until 
time synchronization has been completed.


### The Changed Systemd Service File

```sh
# z-way-server.service: systemd service file

[Unit]
Description=z-way-server.service: Z-Way
Wants=time-sync.target
After=time-sync.target
OnFailure=exam_coredump.service

[Service]
User=root
Group=root

Environment=PATH=/bin:/usr/bin:/sbin:/usr/sbin
WorkingDirectory=/opt/z-way-server
ExecStart=/opt/z-way-server/z-way-server

Restart=on-failure
RestartSec=2min

[Install]
WantedBy=multi-user.target
```

### Installation

1. check the state of the timesyncd service:<br>
   `sudo systemctl status systemd-timesyncd.service --no-pager`<br>
   `timedatectl status`
2. install and start the timesyncd service, if not yet done:<br>
   `sudo systemctl enable systemd-time-wait-sync.service`<br>
   `sudo systemctl start systemd-time-wait-sync.service`
3. replace the Systemd service file:<br>
   `./install_systemd.bash z-way-server.service.timesync`<br>

Note: In file /etc/systemd/timesyncd.conf it's possible to define a local
time server.

Note: Another time service software may have to be terminated and 
deactivated (e.g. ntp, chrony, ...).

### timedatectl Commands

`systemctl status systemd-timesyncd.service --no-pager`<br>
`timedatectl status`<br>
`timedatectl timesync-status`<br>
`timedatectl show-timesync`

