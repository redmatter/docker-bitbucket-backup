#!/bin/sh

/bin/gzip -c ${BITBUCKET_BACKUP_LOG} > ${BITBUCKET_BACKUP_LOG}.$(date +%Y%m%d).gz &&
	cat /dev/null > ${BITBUCKET_BACKUP_LOG}
