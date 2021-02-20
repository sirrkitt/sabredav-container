#!/bin/sh

addgroup -S -g $PGID unit
adduser -S -h /srv/sabredav -D -H -s /sbin/nologin -u $PUID -G unit unit

chown -R $PUID:$PGID /srv/sabredav /data


if [ -e /socket/sabredav/sabredav.sock ]
then
	rm /socket/sabredav/sabredav.sock
fi
if [ "$AUTOCONFIG" == "YES" ]
then
	/opt/sbin/unitd
	curl --data-binary @/config/unit/config.json -X PUT --unix-socket /socket/control/control.unit.sock http://localhost/config/
	pkill unitd
fi

rm /socket/sabredav/sabredav.sock
exec /opt/sbin/unitd --no-daemon
