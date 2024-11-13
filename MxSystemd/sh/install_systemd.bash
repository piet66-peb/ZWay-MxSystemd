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
#h Version:      V1.0.0 2024-10-21/peb
#v History:      V1.0.0 2024-02-24/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='install_systemd.bash'
VERSION='V1.0.0'
WRITTEN='2024-10-21/peb'

#b Variables
#-----------
t_dir=/etc/systemd/system
s=z-way-server

r_file="$1"
[ "$r_file" == "" ] && r_file="$s.service"

t_file="$r_file"
extension="${t_file##*.}"
if [ $extension != 'service' ]
then
    t_file="$s.service"
fi

#b Commands
#----------
echo sudo cp `dirname $0`/$r_file $t_dir/$t_file
sudo cp `dirname $0`/$r_file $t_dir/$t_file

echo sudo systemctl daemon-reload
sudo systemctl daemon-reload

#sudo systemctl enable $s
#sudo systemctl start $s
#sudo systemctl status $s --no-pager

