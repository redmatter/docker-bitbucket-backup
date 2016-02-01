#!/bin/sh

touch_crontab() {
	touch $(find /var/spool/cron/crontabs)
}

(sleep 5; touch_crontab)&
exec /usr/sbin/cron -f -L15
