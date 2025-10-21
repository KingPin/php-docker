# PHP Docker Images

Multi-architecture PHP Docker images with extensive extensions for modern web development.

[![Docker Pulls](https://img.shields.io/docker/pulls/kingpin/php-docker)](https://hub.docker.com/r/kingpin/php-docker)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/kingpin/php-docker/docker-ci.yml?branch=main)](https://github.com/kingpin/php-docker/actions/workflows/docker-ci.yml)

> **⚠️ Deprecation Notice**: PHP 7.x, 8.0 and 8.1 builds are **no longer published**. Existing images remain available in registries for backwards compatibility. See [Deprecated Versions](#deprecated-versions) below.

## 🎯 Which Image Should I Use?

**New projects or need process supervision?** → Use **v2** images (e.g., `8.3-fpm-alpine-v2`)  
**Existing deployments or maximum compatibility?** → Use **v1** images (e.g., `8.3-fpm-alpine`)

See [v1 vs v2 comparison](#v1-vs-v2-comparison) below for details.

## Features

- **Multi-Architecture Support**: Works on `amd64`, `arm64/aarch64` and `arm32v7/armhf` platforms
- **Multiple PHP Versions**: PHP 8.2, 8.3, and 8.4 (actively built); PHP 7.x, 8.0, and 8.1 deprecated
- **Multiple Server Types**: CLI, FPM, and Apache
- **Base OS Options**: Alpine (lightweight) and Debian (Bookworm/Bullseye)
- **Extensive Extensions**: 30+ PHP extensions pre-installed
- **Latest Composer**: Always ships with the latest Composer version
- **Image Processing Tools**: Includes ImageMagick, GD, and various image optimization utilities
- **Apache Mods**: Includes Apache rewrite module (for Apache variants)
- **v2: s6-overlay init**: Proper PID 1 and service supervision for reliable multi-process containers

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

### v1 (Legacy/Compatible)

```bash
# Run PHP CLI
docker run --rm kingpin/php-docker:8.3-cli-alpine php -v

# Run with your code mounted
docker run --rm -v $(pwd):/app -w /app kingpin/php-docker:8.3-cli-alpine php script.php

# Start PHP-FPM server
docker run -d -p 9000:9000 -v $(pwd):/var/www/html kingpin/php-docker:8.3-fpm-alpine
```

### v2 (Modern/Supervised)

```bash
# Run PHP CLI with s6-overlay
docker run --rm kingpin/php-docker:8.3-cli-alpine-v2 php -v

# Run with your code mounted
docker run --rm -v $(pwd):/app -w /app kingpin/php-docker:8.3-cli-alpine-v2 php script.php

# Start PHP-FPM with s6 supervision
docker run -d -p 9000:9000 -v $(pwd):/var/www/html kingpin/php-docker:8.3-fpm-alpine-v2
```

## v1 vs v2 Comparison

We maintain **two image variants** to support both existing users and modern use cases:

### v1 (Legacy) - Tags without `-v2` suffix

**Purpose:** Maximum compatibility with existing deployments and stable behavior.

**Key Characteristics:**

- Simpler Dockerfile with fewer runtime layers
- No s6-overlay or external init system
- Builds with standard `docker build` (no BuildKit required)
- Smaller image footprint in some configurations

**Pros:**

✅ Drop-in replacement for existing deployments  
✅ Simpler container runtime behavior  
✅ Smaller learning curve  
✅ No BuildKit dependency for local builds

**Cons:**

❌ Less robust process supervision  
❌ Harder to run multiple services reliably  
❌ No built-in service health monitoring  
❌ May not handle signals properly in all scenarios

**Use v1 when:**

- You have existing containers relying on legacy behavior
- You prefer simpler runtime without init systems
- You need maximum backward compatibility
- You run single-process containers only

### v2 (Modern) - Tags with `-v2` suffix

**Purpose:** Modernized image with s6-overlay for proper init and service supervision.

**Key Characteristics:**

- Uses [s6-overlay](https://github.com/just-containers/s6-overlay) as PID 1 init
- Proper signal handling and zombie process reaping
- Service supervision and restart policies
- BuildKit-enabled for better build performance and caching

**Pros:**

✅ Proper PID 1 and process supervision (s6)  
✅ Safe for running FPM + sidecar processes (e.g., cron, queue workers)  
✅ Better build performance with BuildKit cache mounts  
✅ Easier to add background services and health checks  
✅ Handles container signals properly

**Cons:**

❌ Requires Docker BuildKit/buildx for advanced features  
❌ Slightly larger image due to s6-overlay (~2-3MB)  
❌ Different runtime behavior may require minor adjustments  
❌ More complex init system to understand

**Use v2 when:**

- You need reliable multi-process containers
- You want proper signal handling and process supervision
- You're starting a new project
- You run background workers or cron alongside FPM

> **Migration Guide:** See [docs/migration.md](docs/migration.md) for detailed migration steps and compatibility notes.

## Troubleshooting

For common issues and solutions, see [docs/troubleshooting.md](docs/troubleshooting.md).

Quick tips:

- **Container exits immediately**: For CLI variants, provide a long-running command
- **Permission issues**: Match container UID with host UID using `-u` flag
- **Missing extensions**: Extend the image and use `install-php-extensions`
- **v2 build fails locally**: Enable Docker BuildKit or install buildx plugin
- **v2 s6-overlay not found**: Ensure you're using the `-v2` tag

## Local Development & Testing

For contributors and advanced users, see [docs/local-build.md](docs/local-build.md) for:

- Using the `test-build.sh` helper script
- Building both v1 and v2 variants locally
- Running smoke tests

## CI/CD & Publishing

Images are automatically built, tested, and published via GitHub Actions:

- **All branches/PRs**: Build and test only (no publishing)
- **`main` branch**: Build, test, and publish to all registries

For more details, see [docs/ci.md](docs/ci.md).

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

- **Docker Hub**: `docker.io/kingpin/php-docker`
- **GitHub Container Registry**: `ghcr.io/kingpin/php-docker`
- **Quay.io**: `quay.io/kingpinx1/php-docker`

All registries have identical image content and tags.

## Available Tags

### Tag Format

- **v1 images**: `{php-version}-{type}-{os}` (e.g., `8.3-fpm-alpine`)
- **v2 images**: `{php-version}-{type}-{os}-v2` (e.g., `8.3-fpm-alpine-v2`)

### Current Supported Images

Both v1 and v2 variants are available for all combinations below:

| PHP Version | Type   | OS        | v1 Tag Example         | v2 Tag Example             |
|-------------|--------|-----------|------------------------|----------------------------|
| 8.3         | CLI    | Alpine    | `8.3-cli-alpine`       | `8.3-cli-alpine-v2`        |
| 8.3         | CLI    | Bookworm  | `8.3-cli-bookworm`     | `8.3-cli-bookworm-v2`      |
| 8.3         | FPM    | Alpine    | `8.3-fpm-alpine`       | `8.3-fpm-alpine-v2`        |
| 8.3         | FPM    | Bookworm  | `8.3-fpm-bookworm`     | `8.3-fpm-bookworm-v2`      |
| 8.3         | Apache | Bookworm  | `8.3-apache-bookworm`  | `8.3-apache-bookworm-v2`   |
| 8.2         | CLI    | Alpine    | `8.2-cli-alpine`       | `8.2-cli-alpine-v2`        |
| 8.2         | CLI    | Bookworm  | `8.2-cli-bookworm`     | `8.2-cli-bookworm-v2`      |
| 8.2         | FPM    | Alpine    | `8.2-fpm-alpine`       | `8.2-fpm-alpine-v2`        |
| 8.2         | FPM    | Bookworm  | `8.2-fpm-bookworm`     | `8.2-fpm-bookworm-v2`      |
| 8.2         | Apache | Bookworm  | `8.2-apache-bookworm`  | `8.2-apache-bookworm-v2`   |
| 8.4         | CLI    | Alpine    | `8.4-cli-alpine`       | `8.4-cli-alpine-v2`        |
| 8.4         | CLI    | Bookworm  | `8.4-cli-bookworm`     | `8.4-cli-bookworm-v2`      |
| 8.4         | FPM    | Alpine    | `8.4-fpm-alpine`       | `8.4-fpm-alpine-v2`        |
| 8.4         | FPM    | Bookworm  | `8.4-fpm-bookworm`     | `8.4-fpm-bookworm-v2`      |
| 8.4         | Apache | Bookworm  | `8.4-apache-bookworm`  | `8.4-apache-bookworm-v2`   |

> **Note:** PHP 8.1+ images are built on Bookworm (Debian 12). Bullseye tags redirect to Bookworm for PHP 8.1+.

### Deprecated Tags (v1 only)

The following tags are deprecated and will not be built going forward, but remain available in registries for backwards compatibility:

- PHP 7.x:
  - `7-cli-bullseye`, `7-cli-alpine`
  - `7-fpm-bullseye`, `7-fpm-alpine`
  - `7-apache-bullseye`

- PHP 8.0:
  - `8-cli-bullseye`, `8-cli-alpine`
  - `8-fpm-bullseye`, `8-fpm-alpine`
  - `8-apache-bullseye`

- PHP 8.1:
  - `8.1-cli-bullseye`, `8.1-cli-bookworm`, `8.1-cli-alpine`
  - `8.1-fpm-bullseye`, `8.1-fpm-bookworm`, `8.1-fpm-alpine`
  - `8.1-apache-bullseye`, `8.1-apache-bookworm`

> **Important:** These versions are deprecated. Please upgrade to PHP 8.2, 8.3, or 8.4 for security and performance.

## 📊 Image Sizes

Approximate compressed sizes (v1 / v2):

| Type   | OS        | v1 Size | v2 Size  | Delta    |
|--------|-----------|---------|----------|----------|
| CLI    | Alpine    | ~80MB   | ~83MB    | +3MB     |
| CLI    | Bookworm  | ~140MB  | ~143MB   | +3MB     |
| FPM    | Alpine    | ~85MB   | ~88MB    | +3MB     |
| FPM    | Bookworm  | ~150MB  | ~153MB   | +3MB     |
| Apache | Bookworm  | ~180MB  | ~183MB   | +3MB     |

> v2 overhead is primarily the s6-overlay binaries (~2-3MB per image).

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

## Deprecated Versions

The following PHP versions are **no longer actively built** but remain available in registries for backwards compatibility:

### PHP 7.x (End of Life)
- All PHP 7.x images (7.4 and earlier)
- Last published: January 2025
- Available tags: `7-cli-alpine`, `7-fpm-alpine`, `7-apache-bullseye`, etc.

### PHP 8.1 (End of Active Support)
- All PHP 8.1 images
- Last published: January 2025
- Available tags: `8.1-cli-alpine`, `8.1-fpm-alpine`, `8.1-apache-bookworm`, etc.

**Migration Path:**
- Upgrade to PHP 8.2 or 8.3 for continued security updates and new builds
- See [migration guide](docs/migration.md) for upgrade assistance
- Existing images will remain available in Docker Hub, GHCR, and Quay.io

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
2. **Create a feature branch**: `git checkout -b feature/new-extension`
3. **Make your changes** (update both `Dockerfile.v1` and `Dockerfile.v2` if applicable)
4. **Test locally**: Use `test-build.sh` to verify builds
5. **Submit a Pull Request**

### Guidelines

- Follow the existing code style and conventions
- Test both v1 and v2 variants when making changes
- Update documentation as needed
- Keep PRs focused on a single change
- Reference issues in commit messages

Our CI/CD pipeline will automatically test your changes when you submit a PR.

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

---

**Need help?** Open an issue or check our [troubleshooting guide](docs/troubleshooting.md).
