#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         download_MxSystemd.bash
#h Type:         Linux shell script
#h Purpose:      download the MxSystemd package from Github and copy it to the 
#h               Z-Way folder userModules
#h Project:      
#h Usage:        <path>/download_MxSystemd.bash
#h               or with wget:
#h               url=https://github.com/piet66-peb/ZWay-MxSystemd/raw/refs/heads/main/download_MxSystemd.bash
#h               cd /tmp; wget -q -O - $url | sudo bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.1.1 2025-02-14/peb
#v History:      V1.0.0 2024-10-02/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='download_MxSystemd.bash'
VERSION='V1.1.1'
WRITTEN='2025-02-14/peb'

#b Variables
#-----------
pack=MxSystemd

#b Commands
#----------
gitpack=ZWay-$pack
gitzip=$gitpack.zip
url=https://github.com/piet66-peb/$gitpack/archive/refs/heads/main.zip
tardir=/opt/z-way-server/automation/userModules/
tmp=/tmp

echo change dir to $tmp...
cd $tmp
[ $? -eq 0 ] || exit 1

echo downloading $gitzip...
wget -O $gitzip $url
[ $? -eq 0 ] || exit 1

echo extracting $gitzip...
sudo unzip $gitzip
[ $? -eq 0 ] || exit 1

echo copying $pack to $tardir...
#sudo cp -dpR ${gitpack}-main/${pack} $tardir
[ $? -eq 0 ] || exit 1

echo done.

