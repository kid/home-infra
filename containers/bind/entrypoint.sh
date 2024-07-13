#!/usr/bin/env sh

# Mikrotik mounts the volume as noexec,
# so we add a+x so that named can travese it
chmod a+x,g+w /etc/bind
chgrp named /etc/bind

if [ ! -d /etc/bind/journals ]; then
	mkdir /etc/bind/journals
	chgrp named /etc/bind/journals
	chmod a+x,g+w /etc/bind/journals
	touch /etc/bind/journals/.type
fi

exec "$@"
