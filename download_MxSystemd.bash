#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         download_MxSystemd.bash
#h Type:         Linux shell script
#h Purpose:      download the MxSystemd package from Github and copy it to the 
#h               Z-Way folder userModules
#h Project:      
#h Usage:        <path>/download_MxSystemd.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.0.0 2024-10-02/peb
#v History:      V1.0.0 2024-10-02/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='download_MxSystemd.bash'
VERSION='V1.0.0'
WRITTEN='2024-10-02/peb'

#b Variables
#-----------
pack=MxSystemd

#b Commands
#----------
gitpack=ZWay-$pack
url=https://github.com/piet66-peb/$gitpack/archive/refs/heads/main.zip
tardir=/opt/z-way-server/automation/userModules/
cd /tmp; wget -O $gitpack.zip $url | unzip ${gitpack}.zip | sudo cp -dpR ${gitpack}-main/${pack} $tardir

