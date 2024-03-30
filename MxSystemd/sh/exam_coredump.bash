#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         exam_coredump.bash
#h Type:         Linux shell script
#h Purpose:      examines the coredump, after z-way-server-failed and before it is
#h               restarted
#h Project:      
#h Installation: edit and install systemd service file z-way-server.service.restart
#h Usage:        [sudo] <dir>/exam_coredump.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    coredumpctl (systemd-coredump), lz4
#h Platforms:    Linux with systemd/systemctl
#h Authors:      peb piet66
#h Version:      V1.0.0 2024-03-30/peb
#v History:      V1.0.0 2024-03-26/peb first version
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='exam_coredump.bash'
VERSION='V1.0.0'
WRITTEN='2024-03-30/peb'

#b Variables
#-----------
SERVICE=z-way-server
BASEDIR=`dirname $0`
PARAMS=${BASEDIR}/params
[ -e "$PARAMS" ] && . "$PARAMS"

[ "$EXAM_DIR" == "" ] && EXAM_DIR="$BASEDIR"
COREDUMP=coredump_decomp
currtime=$(date +%s)
COREDUMP_EXAM="${currtime}_coredump_exam"

#b Functions
#-----------
function collect_data
{
    echo -e "\n===== status after failure:\n"
    echo systemctl status $SERVICE --no-pager -l
    systemctl status $SERVICE --no-pager -l

    echo -e "\n===== journalctl:\n"
    echo journalctl MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 -o verbose --no-pager
    journalctl MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 -o verbose --no-pager

    echo -e "\n===== coredumpctl output:\n"
    echo coredumpctl list -1 $SERVICE
    coredumpctl list -1 $SERVICE
    [ $? -ne 0 ] && return 1

    echo -e "\ncoredumpctl info --no-pager -1 $SERVICE"
    coredumpctl info --no-pager -1 $SERVICE

    echo -e "\n===== core dump file (lz4 compressed):\n"
    STORAGE=`coredumpctl info --no-pager -1 $SERVICE | grep "Storage:" | cut -d':' -f2`
    EXECUTABLE=`coredumpctl info --no-pager -1 $SERVICE | grep "Executable:" | cut -d':' -f2`
    echo $STORAGE

    echo -e "\n======= getfattr:\n"
    echo getfattr --absolute-names -d $STORAGE
    getfattr --absolute-names -d $STORAGE

    echo -e "\n===== gdb:\n"
    #uncompress lz4 file before using with gdb:
    [ -e "$COREDUMP" ] && mv -f "$COREDUMP" "$COREDUMP.previous"
    echo lz4 -dfq $STORAGE $COREDUMP
    lz4 -dfq $STORAGE $COREDUMP 

    echo gdb $EXECUTABLE $COREDUMP --batch --eval-command="bt full"
    gdb $EXECUTABLE $COREDUMP --batch --eval-command="bt full" 2>/dev/null
} #collect_data

function notify
{
    logger -i "$1"
    pushd $BASEDIR >/dev/null 2>&1
        if [ -e emailAccount.cfg ]
        then
            ./sendEmail.bash "$1" "$2" &
        else
            echo 'create an emailAccount.cfg file to get a notification'
        fi
    popd >/dev/null
    echo ''
} #notify

#b Main
#------
current_state=`systemctl is-failed $SERVICE`
if [ $? -eq 0 ]
then
    #b send email
    #------------
    SUBJECT="$SERVICE is failed - restarting..."
    CONTENT="examine core dump to \n   ${EXAM_DIR}/$COREDUMP_EXAM"
    notify "$SUBJECT" "$CONTENT" >"$COREDUMP_EXAM"

    #b examine core dump
    #-------------------
    [ -d "$EXAM_DIR" ] || mkdir -p "$EXAM_DIR"  
    pushd $EXAM_DIR >/dev/null 2>&1
        collect_data >>"$COREDUMP_EXAM"
    popd >/dev/null
else
    #b send email
    #------------
    SUBJECT="$SERVICE($current_state) starting..."
    CONTENT=""
    notify "$SUBJECT" "$CONTENT"
fi
exit 0

