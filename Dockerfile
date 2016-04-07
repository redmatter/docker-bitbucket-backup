FROM debian:jessie

MAINTAINER Dino.Korah@RedMatter.com

ENV TZ="Europe/London" \
	BITBUCKET_USER=daemon \
	BITBUCKET_GROUP=daemon \
	BITBUCKET_BACKUP_HOME=/app/atlassian/bitbucket/backup \
	BITBUCKET_BACKUP_USER=backup \
	BITBUCKET_BACKUP_PASS=letmein \
	BITBUCKET_URL=http://bitbucket \
	MYSQL_HOST=mysql \
	MYSQL_DATABASE=bitbucket \
	MYSQL_USER=atlbitbucket \
	MYSQL_PASSWORD=letmein
ENV BITBUCKET_BACKUP_LOG=${BITBUCKET_BACKUP_HOME}/log/bitbucket-backup.log

# pull in the bits we need for the build
ADD https://bitbucket.org/redmatter-uk/atlassian-bitbucket-diy-backup/get/b51c17ca285b.zip /tmp/files.zip
COPY start-cron.sh bash_set_u.patch bitbucket.diy-backup.vars.sh rotate-log.sh /tmp/

RUN ( \
		export DEBIAN_FRONTEND=noninteractive; \
		export BUILD_DEPS="patch unzip"; \
		export APP_DEPS="tar mysql-client jq rsync bash curl cron sudo ca-certificates"; \

		# so that each command can be seen clearly in the build output
		set -e -x; \

		# update and upgrade for vulnerability fixes etc.
		apt-get update; \
		apt-get upgrade -y; \
		apt-get install --no-install-recommends -y $BUILD_DEPS $APP_DEPS ; \

		# We need to create the user and group that is used by bitbucket, in this container as well
		# Need to make sure that the UID and GID are the same; 167 has been allocated for this purpose (refer confluence)
		if id -u ${BITBUCKET_USER} &>/dev/null; then \
			_groups=" $(id -nG ${BITBUCKET_USER}) "; \
			(echo "$_groups" | grep -q " ${BITBUCKET_GROUP} ") || usermod -aG ${BITBUCKET_GROUP} ${BITBUCKET_USER}; \
			(echo "$_groups" | grep -q " crontab ") || usermod -aG crontab ${BITBUCKET_USER}; \
		else \
			groupadd -rg 167 ${BITBUCKET_GROUP} ; \
			useradd -mrg ${BITBUCKET_GROUP} -G crontab -u 167 ${BITBUCKET_USER}; \
		fi; \

		mkdir -p ${BITBUCKET_BACKUP_HOME} ; \
		cd ${BITBUCKET_BACKUP_HOME} ; \

		mkdir -p log bin archives tmp tmp/bitbucket-db tmp/bitbucket-home /var/atlassian/application-data/bitbucket ; \
		touch ${BITBUCKET_BACKUP_LOG} ; \

		# extract the archive, apply patch and add the config
		unzip -j -d bin /tmp/files.zip ; \
		patch -d bin -p1 < /tmp/bash_set_u.patch ; \
		rm /tmp/files.zip /tmp/bash_set_u.patch ; \
		mv /tmp/bitbucket.diy-backup.vars.sh /tmp/rotate-log.sh bin ; \

		# set correct permissions
		chown -R ${BITBUCKET_USER}:${BITBUCKET_GROUP} . /var/atlassian/application-data/bitbucket ; \
		chmod -R go-rwx bin tmp archives /var/atlassian/application-data/bitbucket ; \

		mv /tmp/start-cron.sh /. ; \
		chmod -R go-w /start-cron.sh ; \

		# setup daily cron
		# remove the ones that come with the package; no need for that
		rm -f /etc/cron.daily/* ; \
		# give sudo permission for the user on cron start script
		echo "${BITBUCKET_USER} ALL=(ALL) NOPASSWD:SETENV: /start-cron.sh" > /etc/sudoers.d/cron ; \
		( \
			echo "0 0 * * * ${BITBUCKET_BACKUP_HOME}/bin/bitbucket.diy-backup.sh >${BITBUCKET_BACKUP_LOG} 2>&1"; \
			echo "50 23 * * * ${BITBUCKET_BACKUP_HOME}/bin/rotate-log.sh >/dev/null 2>&1"; \
		) | /usr/bin/crontab -u ${BITBUCKET_USER} - ; \
		chmod go-rwx /var/spool/cron/crontabs/${BITBUCKET_USER} ; \
		chown ${BITBUCKET_USER}:crontab /var/spool/cron/crontabs/${BITBUCKET_USER} ; \

		# remove packages that we don't need
		apt-get remove -y $BUILD_DEPS ; \
		apt-get autoremove -y ; \
		apt-get clean; \
		rm -rf /var/lib/{apt,dpkg,cache,log}/; \
	)

WORKDIR ${BITBUCKET_BACKUP_HOME}

VOLUME [ "${BITBUCKET_BACKUP_HOME}/archives", "${BITBUCKET_BACKUP_HOME}/log", "/var/atlassian/application-data/bitbucket" ]

USER ${BITBUCKET_USER}

CMD ["sudo", "-E", "/start-cron.sh"]
