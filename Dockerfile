FROM alpine:3.13 AS builder

RUN apk add --no-cache alpine-sdk imap-dev curl-dev icu-dev postgresql-dev pcre2-dev zlib-dev libxml2-dev oniguruma-dev sqlite-dev openldap-dev libzip-dev

WORKDIR	/tmp/php
RUN	wget https://www.php.net/distributions/php-8.0.2.tar.bz2 && tar xvf php-8.0.2.tar.bz2 && cd php-8.0.2 &&\
	./configure --prefix=/opt --with-config-file-path=/config/php --with-config-file-scan-dir=/config/php/conf.d --disable-fpm --enable-embed=shared --enable-shared=yes --disable-cgi --with-pcre-jit --enable-calendar --with-curl --with-imap --with-imap-ssl --enable-intl --enable-mbstring --with-ldap --with-pdo-mysql --with-pdo-pgsql --with-pgsql --enable-sockets --with-zip --disable-phpdbg --with-zlib --enable-simplexml --without-pear --with-openssl &&\
	make -j32 && make install

WORKDIR /tmp/unit
RUN	wget https://unit.nginx.org/download/unit-1.22.0.tar.gz && tar xvf unit-1.22.0.tar.gz && cd unit-1.22.0 &&\
	./configure --prefix=/opt --openssl --control=unix:/socket/control/control.unit.sock --log=/dev/stdout --state=/config/unit/state --pid=/run/unit.pid --user=unit --group=unit &&\
	make -j32 && make install &&\
	./configure php --config=/opt/bin/php-config --lib-path=/opt/lib/ --module=php &&\
	make php -j32 && make php-install

WORKDIR /tmp/composer
RUN	/opt/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &&\
	/opt/bin/php composer-setup.php --install-dir=/opt/bin --filename=composer &&\
	/opt/bin/php -r "unlink('composer-setup.php');"

WORKDIR /tmp/sabredav
RUN	env PATH=$PATH:/opt/bin composer require sabre/dav ~4.1.5

FROM	alpine:3.13

ENV	PUID=1010
ENV	PGID=1010

COPY	--from=builder /opt /opt
COPY	--from=builder /tmp/sabredav /srv/sabredav
COPY	server.php /srv/sabredav/server.php

COPY	extensions.ini /config/php/conf.d/extensions.ini
COPY	settings.ini /config/php/php.ini

COPY	config.json /config/unit/config.json

RUN	mkdir -p /config/unit/state

COPY	entrypoint.sh /entrypoint.sh
RUN	chmod +x /entrypoint.sh

RUN	apk --no-cache add openssl imap-dev pcre2-dev libxml2-dev oniguruma sqlite-libs libldap libcurl curl icu-libs libpq libzip

VOLUME	[ "/socket/control", "/socket/sabredav", "/data"]

CMD	entrypoint.sh
