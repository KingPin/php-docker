# Troubleshooting Guide

Common issues and solutions for PHP Docker images (v1 and v2).

## General Issues

### Container Exits Immediately

**Symptom:** Container stops right after starting.

**Common Causes:**
- CLI variants need a long-running command
- Overriding CMD/ENTRYPOINT incorrectly
- Application crashes during startup

**Solutions:**

For CLI variants, provide a command:
```bash
# Keep container running
docker run -d kingpin/php-docker:8.3-cli-alpine tail -f /dev/null

# Or run a long-running script
docker run -d kingpin/php-docker:8.3-cli-alpine php worker.php
```

For FPM variants, check logs:
```bash
docker logs <container-id>
```

### Permission Issues with Mounted Volumes

**Symptom:** Permission denied when writing to mounted volumes.

**Solution:** Match container UID with host UID:

```bash
# Check your host UID
id -u  # Usually 1000

# Run with matching UID
docker run -u $(id -u):$(id -g) \
  -v $(pwd):/app \
  kingpin/php-docker:8.3-cli-alpine php script.php
```

Or change ownership of mounted directory:
```bash
# On host
sudo chown -R 1000:1000 ./project-dir
```

For docker-compose:
```yaml
services:
  php:
    image: kingpin/php-docker:8.3-fpm-alpine-v2
    user: "1000:1000"  # Match your host UID:GID
    volumes:
      - ./src:/var/www/html
```

### Missing PHP Extension

**Symptom:** Fatal error: Call to undefined function XYZ.

**Solution:** Check if extension is installed, then add if needed:

```bash
# List installed extensions
docker run --rm kingpin/php-docker:8.3-cli-alpine php -m

# If missing, create custom Dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine-v2
RUN install-php-extensions swoole pcntl
```

Common extensions not included by default:
- `swoole`
- `xdebug` (dev only)
- `grpc`
- `protobuf`

### Memory Limit Errors

**Symptom:** Fatal error: Allowed memory size exhausted.

**Solution:** Increase memory limit:

```bash
# Via environment variable
docker run -e PHP_MEMORY_LIMIT=1G kingpin/php-docker:8.3-cli-alpine php script.php

# Or with docker-compose
services:
  php:
    environment:
      PHP_MEMORY_LIMIT: 1G
```

For CLI scripts, you can also use:
```bash
php -d memory_limit=1G script.php
```

### Slow PHP Performance

**Symptom:** PHP scripts running slower than expected.

**Solutions:**

1. **Check OPcache settings:**
```bash
docker run -e PHP_OPCACHE_MEMORY_CONSUMPTION=256 \
  kingpin/php-docker:8.3-fpm-alpine-v2
```

1. **Enable JIT (PHP 8.0+):**
```ini
# Create custom php.ini
opcache.jit_buffer_size=100M
opcache.jit=1255
```

1. **Use Alpine for smaller footprint:**
```bash
# Alpine is lighter than Bookworm
docker pull kingpin/php-docker:8.3-fpm-alpine-v2
```

1. **Profile your code:**
```bash
# Install xdebug for profiling
FROM kingpin/php-docker:8.3-fpm-alpine-v2
RUN install-php-extensions xdebug
```

## v2-Specific Issues

### Build Fails with "mount option requires BuildKit"

**Symptom:** Error during build: `the --mount option requires BuildKit`

**Solution:** Enable BuildKit:

```bash
# Option 1: Use environment variable
DOCKER_BUILDKIT=1 docker build -f Dockerfile.v2 -t myapp:v2 .

# Option 2: Install and use buildx
docker buildx install
docker buildx build -f Dockerfile.v2 -t myapp:v2 .

# Option 3: Enable BuildKit globally (Docker 23.0+)
# Add to /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  }
}
```

For docker-compose:
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.v2
    environment:
      DOCKER_BUILDKIT: 1
```

### s6-overlay Not Found at Runtime

**Symptom:** Error: `/init: not found` or s6 directories missing.

**Solution:** Ensure you're using the correct v2 image tag:

```bash
# Wrong - v1 tag (no s6-overlay)
docker run kingpin/php-docker:8.3-fpm-alpine

# Correct - v2 tag (has s6-overlay)
docker run kingpin/php-docker:8.3-fpm-alpine-v2
```

If building custom images:
```dockerfile
# Ensure base image is v2
FROM kingpin/php-docker:8.3-fpm-alpine-v2  # Note the -v2 suffix
```

### Custom Init Scripts Not Running (v2)

**Symptom:** Scripts in `/docker-entrypoint.d/` don't execute.

**Solution:** v2 uses s6-overlay's init system. Place scripts correctly:

```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine-v2

# For one-time initialization
COPY my-init.sh /etc/cont-init.d/99-my-init
RUN chmod +x /etc/cont-init.d/99-my-init

# For supervised services
COPY my-service-run /etc/services.d/myservice/run
RUN chmod +x /etc/services.d/myservice/run
```

Init script must have proper shebang:
```bash
#!/usr/bin/with-contenv sh
echo "Running custom init"
```

### Background Process Dies (v2)

**Symptom:** Background worker/cron process stops and doesn't restart.

**Solution:** Create an s6 service for supervision:

```bash
# Create service directory
mkdir -p s6-services/worker

# Create run script
cat > s6-services/worker/run <<'EOF'
#!/usr/bin/with-contenv sh
echo "Starting worker..."
exec php /var/www/html/artisan queue:work --tries=3
EOF

chmod +x s6-services/worker/run
```

In Dockerfile:
```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine-v2
COPY s6-services/ /etc/services.d/
```

## Network Issues

### Cannot Connect to Database

**Symptom:** Connection refused when connecting to database.

**Solutions:**

1. **Check network connectivity:**
```bash
docker run --rm kingpin/php-docker:8.3-cli-alpine ping -c 3 db-host
```

1. **Verify database host:**
```yaml
# Use service name in docker-compose
services:
  php:
    environment:
      DB_HOST: mysql  # Not 'localhost'
  mysql:
    image: mysql:8
```

1. **Check database is ready:**
```yaml
services:
  php:
    depends_on:
      mysql:
        condition: service_healthy
  mysql:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 3s
      retries: 5
```

### Port Already in Use

**Symptom:** Error binding to port 9000 (FPM) or 80 (Apache).

**Solution:** Check what's using the port:

```bash
# Find process using port
sudo lsof -i :9000
# or
sudo netstat -tulpn | grep 9000

# Use different port
docker run -p 9001:9000 kingpin/php-docker:8.3-fpm-alpine-v2
```

## Extension-Specific Issues

### GD Extension Missing Specific Format Support

**Symptom:** GD doesn't support WebP/AVIF on ARM.

**Note:** Some image formats (e.g., AVIF) are not available on ARM7 architecture.

**Solution:** Use Bookworm-based image or check architecture:

```bash
# Check GD support
docker run --rm kingpin/php-docker:8.3-cli-alpine php -r "print_r(gd_info());"

# Use bookworm if more format support needed
docker run --rm kingpin/php-docker:8.3-cli-bookworm php -r "print_r(gd_info());"
```

### Redis Extension Not Working

**Symptom:** Class 'Redis' not found.

**Verify extension is loaded:**
```bash
docker run --rm kingpin/php-docker:8.3-cli-alpine php -m | grep redis
```

If loaded but still not working, check Redis server connection:
```bash
# Test Redis connectivity
docker run --rm --link redis:redis \
  kingpin/php-docker:8.3-cli-alpine \
  php -r "var_dump((new Redis())->connect('redis', 6379));"
```

## Debugging Tips

### Enable Verbose Logging

For v2 images, enable s6-overlay debug output:

```bash
docker run -e S6_VERBOSITY=2 kingpin/php-docker:8.3-fpm-alpine-v2
```

### Check PHP Configuration

```bash
# View all PHP settings
docker run --rm kingpin/php-docker:8.3-cli-alpine php -i

# Check specific setting
docker run --rm kingpin/php-docker:8.3-cli-alpine \
  php -r "echo ini_get('memory_limit');"

# List loaded extensions
docker run --rm kingpin/php-docker:8.3-cli-alpine php -m

# View php.ini location
docker run --rm kingpin/php-docker:8.3-cli-alpine php --ini
```

### Interactive Shell Access

Enter running container for debugging:

```bash
# Get shell in running container
docker exec -it <container-id> sh

# Or start container with shell
docker run --rm -it kingpin/php-docker:8.3-cli-alpine sh
```

### Container Resource Limits

Check if container is hitting resource limits:

```bash
# View container stats
docker stats <container-id>

# Check container logs
docker logs <container-id>

# Inspect container details
docker inspect <container-id>
```

### Application-Level Debugging

Enable PHP error display (development only):

```bash
docker run \
  -e PHP_DISPLAY_ERRORS=On \
  -e PHP_ERROR_REPORTING=E_ALL \
  kingpin/php-docker:8.3-fpm-alpine-v2
```

## Getting More Help

If issues persist:

1. **Check GitHub Issues:** [github.com/kingpin/php-docker/issues](https://github.com/kingpin/php-docker/issues)
2. **Review s6-overlay docs:** [github.com/just-containers/s6-overlay](https://github.com/just-containers/s6-overlay)
3. **Open a new issue with:**
   - Image tag used (e.g., `8.3-fpm-alpine-v2`)
   - Full error message and logs
   - Minimal reproduction case (docker-compose.yml or Dockerfile)
   - Steps to reproduce

## Reporting Bugs

When reporting bugs, include:

```bash
# Image information
docker inspect kingpin/php-docker:8.3-fpm-alpine-v2 | grep -A 5 "Created"

# Container logs
docker logs <container-id> 2>&1

# PHP version and extensions
docker run --rm IMAGE php -v
docker run --rm IMAGE php -m

# System information
docker version
docker-compose version  # if applicable
uname -a  # if Linux/Mac
```
