#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         exam_coredump.bash
#h Type:         Linux shell script
#h Purpose:      examines the coredump, after z-way-server-failed
#h               and restarts the server
#h Project:      
#h Installation: edit and install systemd service file z-way-server.service.restart
#h Usage:        sudo <dir>/exam_coredump.bash
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    coredumpctl (systemd-coredump), lz4
#h Platforms:    Linux with systemd/systemctl
#h Authors:      peb piet66
#h Version:      V1.2.0 2025-02-04/peb
#v History:      V1.0.0 2024-03-26/peb first version
#v               V1.2.0 2025-02-04/peb [+]z-way version added
#h Copyright:    (C) piet66 2024
#h
#h-------------------------------------------------------------------------------

#b Constants
#-----------
MODULE='exam_coredump.bash'
VERSION='V1.2.0'
WRITTEN='2025-02-04/peb'

#b Variables
#-----------
SERVICE=z-way-server
pushd `dirname $0` >/dev/null 2>&1
    BASEDIR=`pwd`
popd >/dev/null 2>&1
PARAMS=${BASEDIR}/params
[ -e "$PARAMS" ] && . "$PARAMS"

[ "$EXAM_DIR" == "" ] && EXAM_DIR="$BASEDIR"
COREDUMP=coredump_decomp
currtime=$(date +%s)
COREDUMP_EXAM="${currtime}_coredump_exam"

#b Functions
#-----------
function notify
{
    echo email notification
    pushd $BASEDIR >/dev/null 2>&1
        current_state=`systemctl is-failed $SERVICE`
        SUBJECT="$SERVICE state=$current_state"
        CONTENT="examine core dump to \n   ${EXAM_DIR}/$COREDUMP_EXAM"
        logger -i "$SUBJECT"

        if [ -e emailAccount.cfg ]
        then
            ./sendEmail.bash "$SUBJECT" "$CONTENT"
        else
            echo 'create an emailAccount.cfg file to get a notification'
        fi
    popd >/dev/null
} #notify

function collect_data
{
    echo -e "\n===== versions and system data:\n"
    $BASEDIR/zway_system.bash
    echo ''

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
    echo ''
} #collect_data

#b Main
#------
[ -d "$EXAM_DIR" ] || mkdir -p "$EXAM_DIR"  
pushd $EXAM_DIR >/dev/null 2>&1

    echo '' >"$COREDUMP_EXAM" 2>&1
    logger -is "exam_coredump-bash started..." >>$COREDUMP_EXAM 2>&1
    echo '' >>"$COREDUMP_EXAM" 2>&1

    #b send email
    #------------
    if [ "$MAIL_AFTER_FAILURE" == true ]
    then
        notify >>"$COREDUMP_EXAM" 2>&1
    fi

    #b examine core dump
    #-------------------
    collect_data >>"$COREDUMP_EXAM" 2>&1

    #b at last restart z-way-server if it is not running
    #---------------------------------------------------
    procid=`pidof $SERVICE`
    if [ $? -ne 0 ]
    then
        logger -is "starting $SERVICE..." >>$COREDUMP_EXAM 2>&1
        systemctl start $SERVICE
    else
        logger -is "$SERVICE is already running" >>$COREDUMP_EXAM 2>&1
   fi

    logger -is "exam_coredump-bash finished." >>$COREDUMP_EXAM 2>&1

popd >/dev/null
exit 0

