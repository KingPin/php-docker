ARG VERSION

# First stage: builder
FROM public.ecr.aws/docker/library/php:${VERSION} AS builder
ARG PHPVERSION
ARG BASEOS

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies based on the base OS with BuildKit cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    if [ "$BASEOS" = "bullseye" ]; then \
        echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/bullseye-backports.list && \
        apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y --no-install-recommends \
            curl git zip unzip ghostscript imagemagick \
            optipng gifsicle pngcrush jpegoptim \
            libjpeg-turbo-progs pngquant webp && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "bookworm" ]; then \
        echo 'deb http://deb.debian.org/debian bookworm main' > /etc/apt/sources.list && \
        apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y --no-install-recommends \
            curl git zip unzip ghostscript imagemagick \
            optipng gifsicle pngcrush jpegoptim \
            libjpeg-turbo-progs pngquant webp && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "alpine" ]; then \
        apk update && \
        apk add --no-cache \
            curl git zip unzip ghostscript imagemagick \
            optipng gifsicle pngcrush jpegoptim \
            libjpeg-turbo libjpeg-turbo-utils pngquant libwebp-tools; \
    fi

# Download PHP extension installer
RUN curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions

# Install PHP extensions grouped by category
RUN install-php-extensions \
    # Web development extensions
    json mysqli pdo_mysql pdo_pgsql pgsql soap sockets \
    # Performance & caching extensions
    opcache redis memcached zstd \
    # File operation extensions
    zip bz2 \
    # Utility extensions
    amqp bcmath calendar ctype exif intl imap ldap mbstring \
    mongodb snmp tidy timezonedb uuid vips xsl yaml \
    # Package manager
    @composer

# Enable Apache rewrite mod if applicable
RUN if command -v a2enmod; then \
      a2enmod rewrite headers; \
    fi

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

# Install GD with architecture-specific configuration
RUN case $(uname -m) in \
        x86_64|aarch64) \
            install-php-extensions gd; \
            ;; \
        armv7l) \
            IPE_GD_WITHOUTAVIF=1 install-php-extensions gd; \
            ;; \
        *) \
            install-php-extensions gd; \
            ;; \
    esac

# Second stage: production
FROM public.ecr.aws/docker/library/php:${VERSION}
ARG BASEOS

# Copy installed extensions and configurations from builder
COPY --from=builder /usr/local/ /usr/local/

# Install required system libraries based on OS
RUN if [ "$BASEOS" = "bullseye" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            librabbitmq4 \
            libpng16-16 \
            libmagickwand-6.q16-6 \
            libc-client2007e \
            libsnappy1v5 \
            libpq5 \
            libnetsnmp40 \
            libtidy5deb1 \
            libvips42 \
            libexslt0 \
            libyaml-0-2 \
            libzip4 \
            libmemcached11 \
            ghostscript \
            imagemagick \
            libwebp6 \
            libavif13 \
            libicu67 \
            libldap-2.4-2 \
            libuuid1 && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "bookworm" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            librabbitmq4 \
            libpng16-16 \
            libmagickwand-6.q16-6 \
            libc-client2007e \
            libsnappy1v5 \
            libpq5 \
            libsnmp40 \
            libtidy5deb1 \
            libvips42 \
            libxslt1.1 \
            libyaml-0-2 \
            libzip4 \
            libmemcached11 \
            ghostscript \
            imagemagick \
            libwebp7 \
            libavif15 \
            libicu72 \
            libldap-2.5-0 \
            libuuid1 && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$BASEOS" = "alpine" ]; then \
        apk add --no-cache \
            rabbitmq-c \
            libpng \
            imagemagick \
            c-client \
            snappy \
            libpq \
            net-snmp-libs \
            tidyhtml-libs \
            vips \
            libxslt \
            yaml \
            libzip \
            libmemcached \
            ghostscript \
            libwebp \
            libavif \
            icu-libs \
            openldap-libs \
            libuuid; \
    fi

# Set useful PHP environment variables
ENV PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_POST_MAX_SIZE=64M \
    PHP_MAX_EXECUTION_TIME=300

# Add configuration files
RUN echo "memory_limit = ${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/memory-limit.ini && \
    echo "upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}" > /usr/local/etc/php/conf.d/upload-limit.ini && \
    echo "post_max_size = ${PHP_POST_MAX_SIZE}" > /usr/local/etc/php/conf.d/post-limit.ini && \
    echo "max_execution_time = ${PHP_MAX_EXECUTION_TIME}" > /usr/local/etc/php/conf.d/max-execution-time.ini

# Create non-root user for better security
RUN if [ "$BASEOS" != "alpine" ]; then \
      groupadd --gid 1000 appuser && \
      useradd --uid 1000 --gid 1000 -m appuser; \
    else \
      addgroup -g 1000 -S appuser && \
      adduser -u 1000 -S appuser -G appuser; \
    fi

# Set working directory and permissions
WORKDIR /var/www/html
RUN chown -R appuser:appuser /var/www/html && \
    chmod -R 755 /var/www/html

# Use a non-root user by default
USER appuser

# Set default command
CMD ["php", "-a"]
