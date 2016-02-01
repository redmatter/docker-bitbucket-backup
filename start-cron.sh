#!/bin/bash

# setup a background subshell that would touch crontabs so that they are correctly loaded
# work aroud for some quirks with vixie cron
( sleep 5; touch $(find /var/spool/cron/crontabs) )&

exec /usr/sbin/cron -f -L15
