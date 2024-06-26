ARG VERSION
FROM php:${VERSION}
ARG PHPVERSION
ARG BASEOS

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies based on the base OS
RUN if [ "$BASEOS" = "bullseye" ]; then \
        echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/bullseye-backports.list && \
        apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y --no-install-recommends curl git zip unzip ghostscript imagemagick optipng gifsicle pngcrush jpegoptim libjpeg-turbo-progs pngquant webp && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "bookworm" ]; then \
        echo 'deb http://deb.debian.org/debian bookworm main' > /etc/apt/sources.list && \
        apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y --no-install-recommends curl git zip unzip ghostscript imagemagick optipng gifsicle pngcrush jpegoptim libjpeg-turbo-progs pngquant webp && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "alpine" ]; then \
        apk update && \
        apk add --no-cache curl git zip unzip ghostscript imagemagick optipng gifsicle pngcrush jpegoptim libjpeg-turbo libjpeg-turbo-utils pngquant libwebp-tools; \
    fi

# Add all needed PHP extensions
RUN curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
        install-php-extensions amqp bcmath bz2 calendar ctype exif intl imap json mbstring ldap mcrypt memcached mongodb mysqli \
          opcache pdo_mysql pdo_pgsql pgsql redis snmp soap sockets tidy timezonedb uuid vips xsl yaml zip zstd @composer

# Enable Apache rewrite mod, if applicable
RUN if command -v a2enmod; then a2enmod rewrite; fi

# Add mcrypt and imagick based on PHP version
RUN case "$PHPVERSION" in \
        7|8.0|8.1|8.2) \
            install-php-extensions imagick; \
            ;; \
        8.3) \
            install-php-extensions imagick/imagick@master; \
            ;; \
        *) \
            ;; \
    esac

# Disable AV1 only in armv7
RUN case $(uname -m) in \
        x86_64|aarch64) \
            install-php-extensions gd; \
            ;; \
        armv7l) \
            IPE_GD_WITHOUTAVIF=1 install-php-extensions gd; \
            ;; \
        *) \
            ;; \
    esac

# Set working directory
WORKDIR /var/www/html
