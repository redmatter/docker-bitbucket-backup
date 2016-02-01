FROM debian:jessie

MAINTAINER Dino.Korah@RedMatter.com

ENV TZ="Europe/London" \
	BITBUCKET_USER=atlbitbucket \
	BITBUCKET_GROUP=atlbitbucket \
	BITBUCKET_BACKUP_USER=backup \
	BITBUCKET_BACKUP_PASS=letmein \
	BITBUCKET_URL=http://bitbucket \
	MYSQL_HOST=mysql \
	MYSQL_DATABASE=bitbucket \
	MYSQL_USER=atlbitbucket \
	MYSQL_PASSWORD=letmein
ENV BITBUCKET_BACKUP_LOG=/home/${BITBUCKET_USER}/log/bitbucket-backup.log

# pull in the bits we need for the build
ADD https://bitbucket.org/atlassianlabs/atlassian-bitbucket-diy-backup/get/a2f7e67e9fd8.zip /tmp/files.zip
COPY start-cron.sh bash_set_u.patch bitbucket.diy-backup.vars.sh rotate-log.sh /tmp/

RUN ( \
		DEBIAN_FRONTEND=noninteractive \
		BUILD_DEPS="patch unzip" \
		APP_DEPS="tar mysql-client jq rsync bash curl cron sudo" \

		# so that each command can be seen clearly in the build output
		set -x && \
		
		# update and upgrade for vulnerability fixes etc.
		apt-get update && \
		apt-get upgrade -y && \
		apt-get install --no-install-recommends -y $BUILD_DEPS $APP_DEPS && \

		# We need to create the user and group that is used by bitbucket, in this container as well
		# Need to make sure that the UID and GID are the same; 167 has been allocated for this purpose (refer confluence)
		groupadd -rg 167 ${BITBUCKET_GROUP} && \
		useradd -mrg ${BITBUCKET_GROUP} -G crontab -u 167 ${BITBUCKET_USER} && \

		cd /home/${BITBUCKET_USER} && \

		mkdir -p log bin archives tmp tmp/bitbucket-db tmp/bitbucket-home /var/atlassian/application-data/bitbucket && \
		touch ${BITBUCKET_BACKUP_LOG} && \

		# extract the archive, apply patch and add the config
		unzip -j -d bin /tmp/files.zip && \
		patch -d bin -p1 < /tmp/bash_set_u.patch && \
		rm /tmp/files.zip /tmp/bash_set_u.patch && \
		mv /tmp/bitbucket.diy-backup.vars.sh /tmp/rotate-log.sh bin && \

		# set correct permissions
		chown -R ${BITBUCKET_USER}:${BITBUCKET_GROUP} . /var/atlassian/application-data/bitbucket && \
		chmod -R go-rwx bin tmp archives /var/atlassian/application-data/bitbucket && \

		mv /tmp/start-cron.sh /. && \
		chmod -R go-w /start-cron.sh && \

		# setup daily cron
		# remove the ones that come with the package; no need for that
		rm -f /etc/cron.daily/* && \
		# give sudo permission for the user on cron start script
		echo "${BITBUCKET_USER} ALL=(ALL) NOPASSWD: /start-cron.sh" > /etc/sudoers.d/cron && \
		( \
			echo "0 0 * * * /home/${BITBUCKET_USER}/bin/bitbucket.diy-backup.sh >${BITBUCKET_BACKUP_LOG} 2>&1"; \ 
			echo "50 23 * * * /home/${BITBUCKET_USER}/bin/rotate-log.sh >/dev/null 2>&1"; \
		) | /usr/bin/crontab -u ${BITBUCKET_USER} - && \
		chmod go-rwx /var/spool/cron/crontabs/${BITBUCKET_USER} && \
		chown ${BITBUCKET_USER}:crontab /var/spool/cron/crontabs/${BITBUCKET_USER} && \

		# remove packages that we don't need
		apt-get remove -y $BUILD_DEPS && \
		apt-get autoremove -y && \
		apt-get clean \
	)

WORKDIR /home/${BITBUCKET_USER}

VOLUME [ "/home/${BITBUCKET_USER}/archives", "/var/atlassian/application-data/bitbucket" ]

USER ${BITBUCKET_USER}

CMD ["sudo", "/start-cron.sh"]
