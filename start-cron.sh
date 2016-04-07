#!/bin/bash

cat > /etc/environment <<ENV
BITBUCKET_USER="${BITBUCKET_USER}"
BITBUCKET_GROUP="${BITBUCKET_GROUP}"
BITBUCKET_BACKUP_HOME="${BITBUCKET_BACKUP_HOME}"
BITBUCKET_BACKUP_USER="${BITBUCKET_BACKUP_USER}"
BITBUCKET_BACKUP_PASS="${BITBUCKET_BACKUP_PASS}"
BITBUCKET_URL="${BITBUCKET_URL}"
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_USER="${MYSQL_USER}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
ENV

# setup a background subshell that would touch crontabs so that they are correctly loaded
# work aroud for some quirks with vixie cron
( sleep 5; touch $(find /var/spool/cron/crontabs) )&

exec /usr/sbin/cron -f -L15
