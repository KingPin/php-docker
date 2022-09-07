ARG VERSION
ARG BASEOS
FROM php:${VERSION}
ARG BASEOS

RUN if [ "$BASEOS" = "bullseye" ]; then \
        curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl git zip unzip ghostscript imagemagick && \
        install-php-extensions bcmath bz2 calendar ctype exif gd intl imagick imap json mbstring mcrypt ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis soap sockets tidy timezonedb uuid xsl yaml zip zstd @composer && \
        rm -rf /var/lib/apt/lists/*; \
    fi
RUN if [ "$BASEOS" = "alpine" ]; then \
        apk --update add curl git zip unzip ghostscript imagemagick && \
        curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions bcmath bz2 calendar ctype exif gd intl imagick imap json mbstring mcrypt ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis soap sockets tidy timezonedb uuid xsl yaml zip zstd @composer; \
    fi
RUN if command -v a2enmod; then a2enmod rewrite; fi
