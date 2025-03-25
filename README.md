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

## Environment Variables

The following environment variables can be overridden when running containers:

### Memory Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | Maximum memory a script can consume |
| `PHP_OPCACHE_MEMORY_CONSUMPTION` | `128` | OPCache memory consumption limit |
| `PHP_OPCACHE_INTERNED_STRINGS_BUFFER` | `16` | OPCache interned strings buffer |

### Upload Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_UPLOAD_MAX_FILESIZE` | `64M` | Maximum allowed size for uploaded files |
| `PHP_POST_MAX_SIZE` | `64M` | Maximum size of POST data allowed |
| `PHP_MAX_FILE_UPLOADS` | `20` | Maximum number of files allowed for upload |

### Execution Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MAX_EXECUTION_TIME` | `300` | Maximum execution time of scripts (seconds) |
| `PHP_MAX_INPUT_VARS` | `1000` | Maximum input variables allowed |

### Error Handling
| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_ERROR_REPORTING` | `E_ALL` | Error reporting level |
| `PHP_DISPLAY_ERRORS` | `Off` | Display errors in output |
| `PHP_LOG_ERRORS` | `On` | Log errors to error log |

### Other Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_DATE_TIMEZONE` | `UTC` | Default timezone |
| `PHP_SESSION_GC_MAXLIFETIME` | `1440` | Session garbage collection max lifetime |
| `PHP_OPCACHE_MAX_ACCELERATED_FILES` | `10000` | OPCache maximum number of files |
| `PHP_OPCACHE_REVALIDATE_FREQ` | `0` | How often to check script timestamps |

### Example usage:

```bash
docker run -e PHP_MEMORY_LIMIT=512M -e PHP_MAX_EXECUTION_TIME=600 kingpin/php-docker:8.3-fpm-alpine
```

## 🚀 Quick Start

```bash
# Run PHP CLI
docker run --rm kingpin/php-docker:8.3-cli-alpine php -v

# Run with your code mounted
docker run --rm -v $(pwd):/app -w /app kingpin/php-docker:8.3-cli-alpine php script.php

# Start PHP-FPM server
docker run -d -p 9000:9000 -v $(pwd):/var/www/html kingpin/php-docker:8.3-fpm-alpine
```

## Troubleshooting

### Common Issues and Solutions

#### Container exits immediately
**Issue**: The container stops right after starting.  
**Solution**: For FPM and Apache variants, ensure you're not overriding the CMD. For CLI variants, provide a command that keeps the container running if needed.

```bash
docker run -d kingpin/php-docker:8.3-cli-alpine tail -f /dev/null
```

#### Permission issues with mounted volumes
**Issue**: Permission errors when writing to mounted volumes.  
**Solution**: Match the container's user ID with your host user ID.

```bash
docker run -u $(id -u):$(id -g) -v $(pwd):/app kingpin/php-docker:8.3-cli-alpine php script.php
```

#### Missing PHP extension
**Issue**: Your application requires an extension not included in the image.  
**Solution**: Create a custom Dockerfile to install additional extensions.

```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine
RUN install-php-extensions <extension-name>
```

#### Memory limit errors
**Issue**: PHP script exceeds memory limit.  
**Solution**: Increase the memory limit.

```bash
docker run -e PHP_MEMORY_LIMIT=1G kingpin/php-docker:8.3-cli-alpine php script.php
```

#### Slow PHP performance
**Issue**: PHP scripts running slowly.  
**Solution**: Check OPcache settings and enable JIT for PHP 8.0+.

```bash
docker run -e PHP_OPCACHE_MEMORY_CONSUMPTION=256 kingpin/php-docker:8.3-cli-alpine php script.php
```

## Security Considerations

These images are designed with security in mind:

- **Non-root User**: Containers run as a non-root `appuser` (UID 1000) by default
- **Limited Permissions**: `/var/www/html` directory has appropriate permissions
- **Security Updates**: Images are regularly scanned for vulnerabilities

### Security Best Practices

1. **Never run as root**: Keep the default non-root user or specify your own
   ```bash
   docker run --user 1001:1001 kingpin/php-docker:8.3-fpm-alpine
   ```

2. **Use read-only volumes when possible**
   ```bash
   docker run -v $(pwd)/config:/app/config:ro kingpin/php-docker:8.3-cli-alpine
   ```

3. **Limit capabilities**: Drop unnecessary capabilities
   ```bash
   docker run --cap-drop ALL --cap-add NET_BIND_SERVICE kingpin/php-docker:8.3-apache-bookworm
   ```

4. **Set memory and CPU limits**
   ```bash
   docker run --memory="256m" --cpus="0.5" kingpin/php-docker:8.3-fpm-alpine
   ```

5. **Use secrets management for sensitive data**
   ```bash
   docker run --secret db_password kingpin/php-docker:8.3-cli-alpine
   ```

6. **Regularly update images** to get the latest security patches

## Performance Tuning Tips

### PHP OPcache Optimization

OPcache is enabled by default. Optimize it further with these settings:

```bash
docker run \
  -e PHP_OPCACHE_MEMORY_CONSUMPTION=256 \
  -e PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
  -e PHP_OPCACHE_INTERNED_STRINGS_BUFFER=32 \
  kingpin/php-docker:8.3-fpm-alpine
```

### PHP-FPM Tuning (for FPM variants)

For high-traffic applications, consider creating a custom `www.conf`:

```
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 15
pm.max_requests = 500
```

### Memory Optimization

```bash
docker run \
  -e PHP_MEMORY_LIMIT=128M \
  kingpin/php-docker:8.3-fpm-alpine
```

### JIT Configuration (PHP 8.0+)

For CPU-intensive applications, enable JIT:

```
# Add to custom php.ini
opcache.jit_buffer_size=100M
opcache.jit=1255
```

### Additional Performance Tips

- Use Alpine-based images for lower memory footprint
- Implement proper caching mechanisms (Redis/Memcached)
- Consider using PHP 8.3+ for best performance
- Use `realpath_cache_size` and `realpath_cache_ttl` for applications with many files

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

## Contributing

We welcome contributions to improve these Docker images!

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/new-extension
   ```
3. **Make your changes**
4. **Run tests locally**
   ```bash
   # Test building the image
   docker build --build-arg VERSION=8.3-cli-alpine --build-arg PHPVERSION=8.3 --build-arg BASEOS=alpine -t test-image .
   
   # Verify functionality
   docker run --rm test-image php -m
   ```
5. **Submit a Pull Request**

### Guidelines

- Follow the existing code style and conventions
- Add tests for new features
- Update documentation as needed
- Keep PRs focused on a single change
- Reference issues in commit messages

### Development Workflow

Our CI/CD pipeline will automatically test your changes when you submit a PR.
For significant changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2023 Kingpin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
