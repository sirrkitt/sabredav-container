#!/bin/sh

addgroup -S -g $PGID unit
adduser -S -h /srv/sabredav -D -H -s /sbin/nologin -u $PUID -G unit unit

chown -R $PUID:$PGID /srv/sabredav /data

/opt/sbin/unitd --user unit --group unit
curl --data-binary @/config/unit/config.json -X PUT --unix-socket /socket/control/control.unit.sock http://localhost/config/
pkill unitd
rm /socket/sabredav/sabredav.sock
exec /opt/sbin/unitd --no-daemon --user unit --group unit
