#!/bin/bash

# catch use of undefined variables
set -u

##
# It is recomended to `chmod 600 bitbucket.diy-backup.vars.sh` after copying the template.
##

CURL_OPTIONS="-L -s -f"

# Which database backup script to use (ex: mssql, postgresql, mysql, ebs-collocated, rds)
BACKUP_DATABASE_TYPE=mysql

# Which filesystem backup script to use (ex: rsync, ebs-home)
BACKUP_HOME_TYPE=rsync

# Which archive backup script to use (ex: tar, tar-gpg)
BACKUP_ARCHIVE_TYPE=tar

# Used by the scripts for verbose logging. If not true only errors will be shown.
BITBUCKET_VERBOSE_BACKUP=TRUE

# The base url used to access this bitbucket instance. It cannot end on a '/'
# BITBUCKET_URL=http://bitbucket

# Used in AWS backup / restore to tag snapshots. It cannot contain spaces and it must be under 100 characters long
INSTANCE_NAME=bitbucket

# The username and password for the user used to make backups (and have this permission)
# set from the environment (from docker)
# BITBUCKET_BACKUP_USER="${BITBUCKET_BACKUP_USER}"
# BITBUCKET_BACKUP_PASS="${BITBUCKET_BACKUP_PASS}"

# The name of the database used by this instance.
BITBUCKET_DB=${MYSQL_DATABASE}
# The path to bitbucket home folder (with trailing /)
BITBUCKET_HOME=/var/atlassian/application-data/bitbucket/


# OS level user and group information (typically: 'atlbitbucket' for both)
BITBUCKET_UID=${BITBUCKET_USER}
BITBUCKET_GID=${BITBUCKET_GROUP}

# The path to working folder for the backup
BITBUCKET_BACKUP_ROOT=/home/${BITBUCKET_UID}/tmp
BITBUCKET_BACKUP_DB=${BITBUCKET_BACKUP_ROOT}/bitbucket-db/
BITBUCKET_BACKUP_HOME=${BITBUCKET_BACKUP_ROOT}/bitbucket-home/

# The path to where the backup archives are stored
BITBUCKET_BACKUP_ARCHIVE_ROOT=/home/${BITBUCKET_UID}/archives

# List of repo IDs which should be excluded from the backup
# It should be space separated: (2 5 88)
BITBUCKET_BACKUP_EXCLUDE_REPOS=()

# PostgreSQL options
POSTGRES_HOST=
POSTGRES_USERNAME=
POSTGRES_PASSWORD=
POSTGRES_PORT=5432

# MySQL options
# MYSQL_HOST=${MYSQL_HOST}
MYSQL_USERNAME=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_BACKUP_OPTIONS=

# HipChat options
HIPCHAT_URL=https://api.hipchat.com
HIPCHAT_ROOM=
HIPCHAT_TOKEN=

# Options for the tar-gpg archive type
BITBUCKET_BACKUP_GPG_RECIPIENT=
