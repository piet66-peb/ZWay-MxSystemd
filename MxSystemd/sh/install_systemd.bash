#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         install_systemd.bash
#h Type:         Linux shell script
#h Purpose:      installs Systemd configuration to /etc/systemd/system/
#h Project:      
#h Usage:        ./install_systemd.bash [<replacement file>]
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2024-03-26/peb
#v History:      V1.0.0 2024-02-24/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='install_systemd.bash'
VERSION='V1.0.0'
WRITTEN='2024-03-26/peb'

#b Variables
#-----------
s=z-way-server
t=/etc/systemd/system
r="$1"
[ "$r" == "" ] && r="$s.service"

#b Commands
#----------
echo copy configuration file $r to $t/$s.service
sudo cp `dirname $0`/$r $t/$s.service
sudo systemctl daemon-reload

#sudo systemctl enable $s
#sudo systemctl start $s
#sudo systemctl status $s --no-pager

