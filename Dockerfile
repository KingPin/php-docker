ARG VERSION=latest
ARG BASEOS=bullseye
FROM php:${VERSION}

RUN if [[ -z "$BASEOS" ]] ; then echo Argument not provided ; else echo Argument is $arg ; fi

RUN if [ "$BASEOS" == "bullseye" ]; then \
        curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y curl git zip unzip && \
        install-php-extensions bcmath bz2 calendar ctype exif gd intl imagick imap json mbstring ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis soap sockets tidy timezonedb uuid xsl yaml zip zstd @composer && \
        if command -v a2enmod; then a2enmod rewrite; fi && \
        rm -rf /var/lib/apt/lists/* \
    elif [ "$BASEOS" == "alpine" ]; then \
        apk --update add curl git zip unzip && \
        curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions bcmath bz2 calendar ctype exif gd intl imagick imap json mbstring ldap memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis soap sockets tidy timezonedb uuid xsl yaml zip zstd @composer && \
        if command -v a2enmod; then a2enmod rewrite; fi && \
    fi
