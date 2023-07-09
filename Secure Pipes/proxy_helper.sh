#!/bin/sh

#  proxy_helper.sh
#  Secure Pipes
#
#  Created by Timothy Stonis on 11/10/14.
#  Copyright (c) 2014 Timothy Stonis. All rights reserved.

ACTIVE_SERVICE=$1
PROXY_HOST=$2
PROXY_PORT=$3

OLD_PROXY_HOST=$4
OLD_PROXY_PORT=$5
OLD_PROXY_STATE=$6

echo "Proxy Helper Started"

/usr/sbin/networksetup -setsocksfirewallproxy "$ACTIVE_SERVICE" $PROXY_HOST $PROXY_PORT
echo "INFO:0|PROXY ARGS: $1 $2 $3 $4 $5 $6|-"

# Wait for a command (this is for future expansion when we need to do other sudo tasks)
read -s -n 1 COMMAND
echo "INFO:0|COMMAND SENT: $COMMAND|-"

# Discard the command for now, since the only helper action is to replace the old proxy config
/usr/sbin/networksetup -setsocksfirewallproxy "$ACTIVE_SERVICE" $OLD_PROXY_HOST $OLD_PROXY_PORT
if [ $OLD_PROXY_STATE = 'No' ]; then
    /usr/sbin/networksetup -setsocksfirewallproxystate "$ACTIVE_SERVICE" off
else
    /usr/sbin/networksetup -setsocksfirewallproxystate "$ACTIVE_SERVICE" on
fi

echo "Complete"