#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         remove_systemd.bash
#h Type:         Linux shell script
#h Purpose:      removes Systemd configuration
#h Project:      
#h Usage:        ./remove_systemd.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2024-04-02/peb
#v History:      V1.0.0 2024-02-24/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='remove_systemd.bash'
VERSION='V1.0.0'
WRITTEN='2024-04-02/peb'

#b Variables
#-----------
s=z-way-server
t=/etc/systemd/system/

#b Commands
#----------
echo -e '\n'sudo systemctl disable $s
sudo systemctl disable $s

echo -e '\n'sudo systemctl stop $s
sudo systemctl stop $s

echo -e '\n'sudo rm -f /etc/init.d/$s
sudo rm -f /etc/init.d/$s

echo -e '\n'sudo rm -f /etc/systemd/system/$s.service
sudo rm -f /etc/systemd/system/*$s.service

# and symlinks that might be related
echo -e '\n'sudo rm -f /usr/lib/systemd/system/$s.service
sudo rm -f /usr/lib/systemd/system/*$s.service

echo -e '\n'sudo systemctl daemon-reload
sudo systemctl daemon-reload

echo -e '\n'sudo systemctl reset-failed
sudo systemctl reset-failed

echo -e '\n'sudo systemctl status $s
sudo systemctl status $s

