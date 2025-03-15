# PHP Docker Images

Multi-architecture PHP Docker images with extensive extensions for modern web development.

[![Docker Pulls](https://img.shields.io/docker/pulls/kingpin/php-docker)](https://hub.docker.com/r/kingpin/php-docker)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/kingpin/php-docker/docker-image.yml?branch=main)](https://github.com/kingpin/php-docker/actions/workflows/docker-image.yml)

## Features

- **Multi-Architecture Support**: Works on `amd64`, `arm64/aarch64` and `arm32v7/armhf` platforms
- **Multiple PHP Versions**: PHP 8.1, 8.2, and 8.3
- **Multiple Server Types**: CLI, FPM, and Apache
- **Base OS Options**: Alpine (lightweight) and Debian (Bookworm)
- **Extensive Extensions**: 30+ PHP extensions pre-installed
- **Latest Composer**: Always ships with the latest Composer version
- **Image Processing Tools**: Includes ImageMagick, GD, and various image optimization utilities
- **Apache Mods**: Includes Apache rewrite module (for Apache variants)

## 🚀 Quick Start

```bash
# Run PHP CLI
docker run --rm kingpin/php-docker:8.3-cli-alpine php -v

# Run with your code mounted
docker run --rm -v $(pwd):/app -w /app kingpin/php-docker:8.3-cli-alpine php script.php

# Start PHP-FPM server
docker run -d -p 9000:9000 -v $(pwd):/var/www/html kingpin/php-docker:8.3-fpm-alpine
```


## 📦 Registry Information

These images are available on multiple registries for redundancy and flexibility:

- Docker Hub: `docker.io/kingpin/php-docker`
- GitHub Container Registry: `ghcr.io/kingpin/php-docker`
- Quay.io: `quay.io/kingpinx1/php-docker`

## Available Tags

### Current Supported Images

| PHP Version | Type   | OS        | Tag Example                |
|-------------|--------|-----------|----------------------------|
| 8.1         | CLI    | Bookworm  | `8.1-cli-bookworm`         |
| 8.1         | CLI    | Alpine    | `8.1-cli-alpine`           |
| 8.1         | FPM    | Bookworm  | `8.1-fpm-bookworm`         |
| 8.1         | FPM    | Alpine    | `8.1-fpm-alpine`           |
| 8.1         | Apache | Bookworm  | `8.1-apache-bookworm`      |
| 8.2         | CLI    | Bookworm  | `8.2-cli-bookworm`         |
| 8.2         | CLI    | Alpine    | `8.2-cli-alpine`           |
| 8.2         | FPM    | Bookworm  | `8.2-fpm-bookworm`         |
| 8.2         | FPM    | Alpine    | `8.2-fpm-alpine`           |
| 8.2         | Apache | Bookworm  | `8.2-apache-bookworm`      |
| 8.3         | CLI    | Bookworm  | `8.3-cli-bookworm`         |
| 8.3         | CLI    | Alpine    | `8.3-cli-alpine` (latest)  |
| 8.3         | FPM    | Bookworm  | `8.3-fpm-bookworm`         |
| 8.3         | FPM    | Alpine    | `8.3-fpm-alpine`           |
| 8.3         | Apache | Bookworm  | `8.3-apache-bookworm`      |

> **Note:** PHP 8.1+ are now built on Bookworm (Debian 12). For backward compatibility, using either `bullseye` or `bookworm` in the tag for PHP 8.1+ will give you the Bookworm-based image.

### Deprecated Tags

The following tags are available but no longer built via CI:

- 7-cli-bullseye
- 7-cli-alpine
- 7-apache-bullseye
- 7-fpm-bullseye
- 7-fpm-alpine
- 8.0-cli-bullseye
- 8.0-cli-alpine
- 8.0-apache-bullseye
- 8.0-fpm-bullseye
- 8.0-fpm-alpine

> **Important:** PHP 7.x has been deprecated and is no longer supported. Please upgrade to PHP 8.1 or newer for security and performance improvements.

## 📊 Image Sizes

| Type   | OS        | Approx. Size |
|--------|-----------|--------------|
| CLI    | Alpine    | ~80MB        |
| CLI    | Debian    | ~140MB       |
| FPM    | Alpine    | ~85MB        |
| FPM    | Debian    | ~150MB       |
| Apache | Alpine    | ~95MB        |
| Apache | Debian    | ~180MB       |

## Pre-installed PHP Extensions

### Web Development
- json
- mysqli
- pdo_mysql
- pdo_pgsql
- pgsql
- soap
- sockets

### Image Processing
- gd (no AV1 encoder on ARM7)
- imagick
- exif
- vips

### Performance & Caching
- opcache
- redis
- memcached
- zstd

### File Operations
- zip
- bz2

### Utility Extensions
- amqp
- bcmath
- calendar
- ctype
- intl
- imap
- ldap
- mbstring
- mcrypt
- mongodb
- snmp
- tidy
- timezonedb
- uuid
- xsl
- yaml

## Usage Examples

### Basic usage with Docker

```bash
docker run -d --name php-app kingpin/php-docker:8.3-cli-alpine php -v
```

### With docker-compose

```yaml
services:
  php-fpm:
    image: kingpin/php-docker:8.3-fpm-alpine
    volumes:
      - ./src:/var/www/html
    networks:
      - app-network

  webserver:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    networks:
      - app-network

networks:
  app-network:
```

## WordPress setup guide
For detailed WordPress setup instructions, visit our [guide](https://sumguy.com/install-wordpress-with-php-fpm-caddy-via-docker/).

## Building Custom Images
You can build custom images based on these by extending the Dockerfile:

```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine

# Add your custom configurations
COPY custom-php.ini /usr/local/etc/php/conf.d/

# Install additional extensions if needed
RUN install-php-extensions swoole
```

## 🏗️ Architecture Diagram
```
                ┌───────────────┐
                │   Base Image  │
                │    php:X.Y    │
                └───────┬───────┘
                        │
          ┌─────────────┼─────────────┐
          │             │             │
┌─────────▼────┐ ┌──────▼─────┐ ┌─────▼──────┐
│   Alpine OS  │ │ Bullseye OS│ │ Bookworm OS│
└─────────┬────┘ └──────┬─────┘ └─────┬──────┘
          │             │             │
┌─────────▼────┐ ┌──────▼─────┐ ┌─────▼──────┐
│ Extensions & │ │ Extensions │ │Extensions &│
│  Libraries   │ │  Libraries │ │ Libraries  │
└─────────┬────┘ └──────┬─────┘ └─────┬──────┘
          │             │             │
          └─────────────┼─────────────┘
                        │
             ┌──────────┼──────────┐
             │          │          │
      ┌──────▼───┐ ┌────▼────┐ ┌───▼─────┐
      │   CLI    │ │   FPM   │ │  Apache │
      └──────────┘ └─────────┘ └─────────┘
```
