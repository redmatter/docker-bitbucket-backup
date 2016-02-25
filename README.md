# docker-bitbucket-backup

Docker image to repackage backup scripts with the settings relevant for Red Matter.

The docker image has vixie cron installed, and it is setup to run rightly backups and log rotation.

    0 0 * * * ${BITBUCKET_BACKUP_HOME}/bin/bitbucket.diy-backup.sh >${BITBUCKET_BACKUP_LOG} 2>&1
    50 23 * * * ${BITBUCKET_BACKUP_HOME}/bin/rotate-log.sh >/dev/null 2>&1

