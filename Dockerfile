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
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl git zip unzip ghostscript \
          imagemagick libaom-dev libavif-dev libdav1d-dev libaom0 && \
        DEBIAN_FRONTEND=noninteractive apt install -t bullseye-backports libyuv-dev -y && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# install dependencies for alpine
RUN if [ "$BASEOS" = "alpine" ]; then \
        apk --update add --no-cache curl git zip unzip ghostscript imagemagick; \
    fi

# enable apache rewrite mod
RUN if command -v a2enmod; then a2enmod rewrite; fi

# add all needed php extensions
RUN curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions amqp bcmath bz2 calendar ctype exif gd intl imagick imap json mbstring ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis snmp soap sockets tidy timezonedb uuid vips xsl yaml zip zstd @composer;

# add mcrypt for all php versions less than 8.2
RUN case "$PHPVERSION" in \
        7|8.0|8.1) \
            install-php-extensions mcrypt \
            ;; \
        *) \
            echo no mcrypt needed for php > 8.2; \
            echo PHP version: $PHPVERSION \
            ;; \
    esac

