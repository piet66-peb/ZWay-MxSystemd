#!/bin/bash
#h-------------------------------------------------------------------------------
#h
#h Name:         sendEmail.bash
#h Type:         Linux shell script
#h Purpose:      send email to recipient
#h Project:      
#h Installation: enter your email account data in emailAccount.cfg:
#h               SEND_TO=xxxxx@xxxx.xx     #email address: default receiver
#h               SEND_FROM=xxxxxxx@xxx.xxx #email address: sender
#h               MAILHUB=mail.xxx.xxx:465  #email server
#h               AUTH_USER=xxxxxxx         #server user id
#h               AUTH_PW=xxxxxxxx          #server user password
#h               COPY_TO=xxxxx@xxxx.xx     #email address: receiver of copy
#h
#h Usage:        ./sendEmail.bash <subject> [<optional parameters>]
#h               with optional parameters:
#h                  <mail content>  (string ('\n' = newline, | = newline) or file)
#h                  <receiver>      ('xxxx.@xxxxx.xxx' or 'Name <xxxx.@xxxxx.xxx>')
#h                  <attachments1..n>
#h Result:       
#h Examples:     
#h Outline:      
#h Resources:    curl
#h Platforms:    Linux
#h Authors:      peb piet66
#h Version:      V1.4 2024-01-21/peb
#v History:      V1.0 2019-09-14/peb first version
#h Copyright:    (C) piet66 2019
#h
#h-------------------------------------------------------------------------------
#-----------
#b Constants
#-----------
VERSION='V1.4'
WRITTEN='2024-01-21/peb'

SIGINT=2
SIGTERM=15

LOG_MAX=5

EXIT_CODE=99
RETURN_VALUE='FAILURE'

MAIL_TEXT='./mail.eml'
MAIL_CFG='./emailAccount.cfg'

#-----------
#b Variables
#-----------
_self="${0##*/}"
WD=`pwd`
cd `dirname $0`
LOG=`pwd`/$_self.log

#-----------
#b Functions
#-----------
function welcome
{
    echo $0 "$@"
    echo $_self $VERSION $WRITTEN
    whoami
    umask -S
    echo ' '
    echo $# parameters:
    x=0
    for i; do 
        x=$(( $x + 1 ))
        echo \$$x=$i 
    done
    echo ' '
}

function bye
{
    echo "bye ($*)"
    exit 0
}

function rotate_log
{
      #echo rotating log file...
      if [ -f $LOG.$LOG_MAX ]
      then
        #echo rm -f $LOG.$LOG_MAX
        rm -f $LOG.$LOG_MAX
      fi 

      let N=LOG_MAX-1 
      while [ $N -gt 0 ]
      do
        if [ -f $LOG.$N ]
        then
          let M=N+1 
          #echo mv $LOG.$N $LOG.$M
          mv $LOG.$N $LOG.$M
        fi 
        let N=N-1 
      done

      if [ -f $LOG ]
      then
        #echo mv $LOG $LOG.1
        mv $LOG $LOG.1
      fi 
} #rotate_log

function mail_address
{
     read -a arr <<< "$1"
     len=${#arr[*]}
     if [ $len -ge 2 ]
     then
        last=$((len-1))
         echo "${arr[$last]}"
     else
         echo "$1"
    fi
} #mail_address

function build_mail_text
{
    # header
    echo To: $TO
    echo From: $FROM
    echo Subject: $SUBJECT
    [ ! -z "$COPY" ] && echo CC: $COPY
    echo MIME-Version: 1.0
    #echo ''

    # if no attachment
    if [ ! -e "$1" ]
    then
        # content type
        echo Content-type: text/plain\; charset=utf-8
        echo Content-Transfer-Encoding: 7bit
        echo ''

        # text body
        if [ -e "$CONTENT" ]
        then
            cat "$CONTENT"
        else
            echo -e $CONTENT | sed s/\|/\\\n/g
        fi
        echo ''

    else
        BOUNDARY=------------C2ADAACB8EE8B429845445DF

        # content type
        #echo ''
        echo Content-Type: multipart/mixed\;
        echo ' 'boundary=\"$BOUNDARY\"
        echo ''
        echo This is a multi-part message in MIME format.
        echo --$BOUNDARY

        echo Content-Type: text/plain\; charset=utf-8
        echo Content-Transfer-Encoding: 7bit
        echo ''

        # text body
        if [ -e "$CONTENT" ]
        then
            cat "$CONTENT"
        else
            echo -e $CONTENT | sed s/\|/\\\n/g
        fi
        echo ''

        #looping through all attachments
        for i in "$@" 
        do
            if [ -e "$i"  ]
            then
                name=`basename "$i"`
                echo --$BOUNDARY
                echo Content-Type: text/x-log\; charset=utf-8;\
                echo ' 'name=\"$name\"
                echo Content-Transfer-Encoding: 7bit
                echo Content-Disposition: attachment\;
                echo ' 'filename=\"$name\"
                echo ''
                cat "$i"
                echo ''
            fi
        done
        echo -n --$BOUNDARY--
    fi
} #build_mail_text

function send_email
{
    C="curl -S --url smtps://$MAILHUB $AUTH_METHOD --user $AUTH_USER:$AUTH_PW --mail-from $FROM_ADDR --mail-rcpt $TO_ADDR --upload-file $MAIL_TEXT"
    if [ ! -z "$COPY_ADDR" ]
    then
        C="$C --mail-rcpt $COPY_ADDR"
    fi

    echo $C
    $C

    EXIT_CODE=$?
    echo '$?='$EXIT_CODE
} #send_email

#----------
#b Welcome
#----------
#trap 'bye SIGINT' $SIGINT
#trap 'bye SIGTERM' $SIGTERM

umask g+rw,o+rw >/dev/null

rotate_log
exec 8>&1 9>&2       #save stdout to &8, stderr to &9
exec &>$LOG 

welcome "$@"

#------
#b Main
#------
    #------------------
    #b get account data
    #------------------
    echo reading account data...
    source $MAIL_CFG
    #echo $SEND_TO
    #echo $SEND_FROM
    #echo $MAILHUB
    #echo $AUTH_USER
    #echo $AUTH_PW
    #echo $COPY_TO

    #-----------------
    #b take parameters
    #-----------------
    echo ''
    echo taking parameters...
    SUBJECT="$1"; shift
    CONTENT="$1"; shift
    FROM="$SEND_FROM"
    TO="$1"
    COPY="$COPY_TO"
    if [ -e "$TO" ]
    then
        TO=
    else
        shift
    fi
    [ -z "$TO" ] && TO="$SEND_TO"
    [ "$TO" == 'undefined' ] && TO="$SEND_TO"
    FROM_ADDR=$(mail_address "$FROM")   
    TO_ADDR=$(mail_address "$TO")
    COPY_ADDR=$(mail_address "$COPY")

    echo SUBJECT=$SUBJECT
    echo CONTENT=$CONTENT
    echo FROM=$FROM
    echo TO=$TO
    echo COPY=$COPY
    echo FROM_ADDR=$FROM_ADDR
    echo TO_ADDR=$TO_ADDR
    echo COPY_ADDR=$COPY_ADDR
    echo ATTACHMENTS=$*
    
    #-----------------
    #b build mail text
    #-----------------
    echo ''
    echo building $MAIL_TEXT...
    build_mail_text $* >  $MAIL_TEXT

    #------------
    #b send email
    #------------
    echo ''
    echo sending email...
    send_email
    [ $EXIT_CODE -eq 0 ] && RETURN_VALUE=OK

exec 1>&8 8>&- 2>&9 9>&-     #restore stdout and stderr
echo $RETURN_VALUE
exit $EXIT_CODE
