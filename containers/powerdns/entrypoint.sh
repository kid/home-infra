#!/usr/bin/env sh

DATA_DIR=/var/lib/powerdns
DATA_FILE="$DATA_DIR/pdns.sqlite3"

# Mikrotik stuff
if [ ! -f "$DATA_DIR/.type" ]; then
	touch "$DATA_DIR/.type"
fi

if [ ! -f $DATA_FILE ]; then
	echo "Creating database"
	sqlite3 $DATA_FILE </usr/share/doc/pdns/schema.sqlite3.sql
	chmod 755 $DATA_FILE
	chown pdns:pdns $DATA_FILE
	echo "Done"
fi

cat <<EOF >/etc/pdns/pdns.conf
launch=gsqlite3
gsqlite3-database=$DATA_FILE
api=yes
api-key=${API_KEY:-changeme}
webserver=yes
webserver-address=${WEBSERVER_ADDRESS:-0.0.0.0}
webserver-allow-from=${WEBSERVER_ALLOW_FROM:-0.0.0.0/0}
enable-lua-records=${ENABLE_LUA_RECORDS:-no}
EOF

exec "$@"
