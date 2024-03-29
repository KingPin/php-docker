ARG VERSION
ARG PHPVERSION
ARG BASEOS
FROM php:${VERSION}
ARG BASEOS
ARG PHPVERSION

# install dependencies for debian
RUN if [ "$BASEOS" = "bullseye" ]; then \
        echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/bullseye-backports.list  && \
        DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl git zip unzip ghostscript imagemagick && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# install dependencies for alpine
RUN if [ "$BASEOS" = "alpine" ]; then \
        apk --update add --no-cache curl git zip unzip ghostscript imagemagick; \
    fi

# add all needed php extensions
RUN curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions amqp bcmath bz2 calendar ctype exif intl imap json mbstring ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis snmp soap sockets tidy timezonedb uuid vips xsl yaml zip zstd @composer

# enable apache rewrite mod
RUN if command -v a2enmod; then a2enmod rewrite; fi

# add mcrypt for all php versions less than 8.2
RUN case "$PHPVERSION" in \
        7|8.0|8.1) \
            install-php-extensions mcrypt imagick \
            echo installing mcrypt and imagick for php < 8.2; \
            echo PHP version: $PHPVERSION \
            ;; \
        8.2) \
            install-php-extensions imagick \
            echo installing imagick for php = 8.2; \
            echo no mcrypt for php > 8.1; \
            echo PHP version: $PHPVERSION \
            ;; \
        *) \
            echo no mcrypt for php > 8.1; \
            echo no imagick for php > 8.2; \
            echo PHP version: $PHPVERSION \
            ;; \
    esac

# disable av1 only in arm7
RUN case $(uname -m) in \
        x86_64|aarch64) \
            install-php-extensions gd; \
            echo arch: $(uname -m) \
            ;; \
        armv7l) \
            IPE_GD_WITHOUTAVIF=1 install-php-extensions gd; \
            echo arch: $(uname -m) \
            ;; \
        *) \
            echo o.0 arch: $(uname -m) \
            ;; \
    esac
