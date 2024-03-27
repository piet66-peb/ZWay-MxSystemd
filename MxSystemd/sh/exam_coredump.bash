#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         exam_coredump.bash
#h Type:         Linux shell script
#h Purpose:      examines the coredump, after z-way-server-failed and before it is
#h               restarted
#h Project:      
#h Installation: edit and install systemd service file z-way-server.service.restart
#h Usage:        <dir>/exam_coredump.bash [<exam_dir>]
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    coredumpctl (systemd-coredump), lz4
#h Platforms:    Linux with systemd/systemctl
#h Authors:      peb piet66
#h Version:      V1.0.0 2024-03-27/peb
#v History:      V1.0.0 2024-03-26/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='exam_coredump.bash'
VERSION='V1.0.0'
WRITTEN='2024-03-27/peb'

#b Variables
#-----------
SERVICE=z-way-server
BASEDIR=`dirname $0`
PARAMS=${BASEDIR}/params
EXAM_DIR="$1"
[ "$EXAM_DIR" == "" ] && EXAM_DIR="$BASEDIR"

currtime=$(date +%s)

#b Functions
#-----------
function collect_data
{
    echo -e "\n===== status after failure:\n"
    echo sudo systemctl status $SERVICE --no-pager -l
    sudo systemctl status $SERVICE --no-pager -l

    echo -e "\n===== journalctl:\n"
    echo journalctl MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 -o verbose --no-pager
    journalctl MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 -o verbose --no-pager

    echo -e "\n===== coredumpctl output:\n"
    echo sudo coredumpctl list -1 $SERVICE
    sudo coredumpctl list -1 $SERVICE
    [ $? -ne 0 ] && return 1

    echo -e "\nsudo coredumpctl info --no-pager -1 $SERVICE"
    sudo coredumpctl info --no-pager -1 $SERVICE

    echo -e "\n===== core dump file (lz4 compressed):\n"
    STORAGE=`sudo coredumpctl info --no-pager -1 $SERVICE | grep "Storage:" | cut -d':' -f2`
    EXECUTABLE=`sudo coredumpctl info --no-pager -1 $SERVICE | grep "Executable:" | cut -d':' -f2`
    echo $STORAGE

    echo -e "\n======= getfattr:\n"
    echo sudo getfattr --absolute-names -d $STORAGE
    sudo getfattr --absolute-names -d $STORAGE

    echo -e "\n===== gdb:\n"
    #uncompress lz4 file before using with gdb:
    COREDUMP=${currtime}_coredump
    [ -e "$COREDUMP" ] && sudo mv -f "$COREDUMP" "$COREDUMP.previous"
    echo sudo lz4 -dfq $STORAGE $COREDUMP
    sudo lz4 -dfq $STORAGE $COREDUMP 

    echo sudo gdb $EXECUTABLE $COREDUMP --batch --eval-command="bt full"
    sudo gdb $EXECUTABLE $COREDUMP --batch --eval-command="bt full" 2>/dev/null
}

#b Main
#------
sudo systemctl is-failed $SERVICE >/dev/null
if [ $? -eq 0 ]
then
    #b send email
    #------------
    pushd $BASEDIR >/dev/null 2>&1
        if [ -e emailAccount.cfg ]
        then
            SUBJECT="$SERVICE failed - restarted"
            CONTENT="examine core dump to \n   ${EXAM_DIR}/${currtime}_coredump_exam"
            ./sendEmail.bash "$SUBJECT" "$CONTENT"
        fi
    popd >/dev/null
     
    #b examine core dump
    #-------------------
    [ -d "$EXAM_DIR" ] || mkdir -p "$EXAM_DIR"  
    pushd $EXAM_DIR >/dev/null 2>&1
        collect_data >${currtime}_coredump_exam
    popd >/dev/null
fi
exit 0

