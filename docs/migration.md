# Migration Guide: v1 to v2

This guide helps you migrate from v1 (legacy) to v2 (modern) PHP Docker images.

> **ℹ️ Note on Deprecated Versions**: PHP 7.x and 8.1 are no longer actively built. If you're using these versions, please also review the [deprecated images guide](deprecated-images.md) for upgrade paths to PHP 8.2 or 8.3.

## Should You Migrate?

**Consider migrating to v2 if:**
- You need proper process supervision for multi-process containers
- You run background workers, cron, or queue processors alongside PHP-FPM
- You want better signal handling and zombie process reaping
- You're starting a new project or service
- You want improved build performance with BuildKit caching

**Stick with v1 if:**
- Your existing deployment works perfectly and you don't need new features
- You run single-process containers only (e.g., simple CLI scripts)
- You need the absolute smallest image size
- You prefer simpler runtime behavior without init systems

## Key Differences

### Runtime Init System

**v1:**
- No init system - direct process execution
- Container CMD/ENTRYPOINT runs as PID 1
- No automatic zombie process reaping

**v2:**
- Uses s6-overlay as PID 1
- Proper signal handling (SIGTERM, SIGINT)
- Automatic zombie process cleanup
- Service supervision and restart policies

### Build Requirements

**v1:**
- Standard `docker build` works
- No special requirements

**v2:**
- Requires Docker BuildKit for optimal features
- Enable with: `DOCKER_BUILDKIT=1 docker build ...`
- Or install buildx plugin: `docker buildx install`

### Image Size

**v2 adds ~2-3MB** due to s6-overlay binaries. This is negligible for most use cases.

## Migration Steps

### Step 1: Test in Non-Production

Start by testing v2 images in development or staging:

```bash
# Pull v2 image
docker pull kingpin/php-docker:8.3-fpm-alpine-v2

# Test your application
docker run --rm -v $(pwd):/var/www/html \
  kingpin/php-docker:8.3-fpm-alpine-v2 php -v
```

### Step 2: Update docker-compose.yml

Change image tags from v1 to v2:

```yaml
# Before (v1)
services:
  php-fpm:
    image: kingpin/php-docker:8.3-fpm-alpine
    volumes:
      - ./src:/var/www/html

# After (v2)
services:
  php-fpm:
    image: kingpin/php-docker:8.3-fpm-alpine-v2
    volumes:
      - ./src:/var/www/html
```

### Step 3: Test Application Functionality

Run your test suite and verify:

```bash
# Start services
docker-compose up -d

# Run tests
docker-compose exec php-fpm vendor/bin/phpunit

# Check logs for s6 messages
docker-compose logs php-fpm
```

You should see s6-overlay initialization messages at container startup.

### Step 4: Verify File Paths and Permissions

Both v1 and v2 use the same directory structure and permissions, but verify:

```bash
# Check directory permissions
docker run --rm kingpin/php-docker:8.3-fpm-alpine-v2 \
  ls -la /var/www/html /tmp

# Verify PHP configuration
docker run --rm kingpin/php-docker:8.3-fpm-alpine-v2 \
  php --ini
```

### Step 5: Update CI/CD Pipelines

If you build custom images, enable BuildKit:

```yaml
# GitHub Actions example
- name: Build v2 image
  env:
    DOCKER_BUILDKIT: 1
  run: |
    docker build -f Dockerfile.v2 -t myapp:v2 .
```

Or use buildx:

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build v2 image
  uses: docker/build-push-action@v5
  with:
    context: .
    file: Dockerfile.v2
    tags: myapp:v2
```

### Step 6: Staged Rollout

For production deployments, use a staged rollout:

1. **Canary deployment**: Deploy v2 to a small percentage of traffic
2. **Monitor metrics**: Watch error rates, response times, memory usage
3. **Gradual increase**: Slowly increase v2 traffic percentage
4. **Full cutover**: Switch all traffic to v2 when confident

## Compatibility Notes

### Environment Variables

All environment variables from v1 work identically in v2:

```bash
# These work the same in both v1 and v2
docker run -e PHP_MEMORY_LIMIT=512M \
  -e PHP_MAX_EXECUTION_TIME=600 \
  kingpin/php-docker:8.3-fpm-alpine-v2
```

### Volume Mounts

Volume paths are identical:

```bash
# Same volume paths for both versions
-v ./src:/var/www/html
-v ./php.ini:/usr/local/etc/php/conf.d/custom.ini
```

### PHP Extensions

All pre-installed extensions are identical between v1 and v2:

```bash
# Same extensions available
docker run --rm kingpin/php-docker:8.3-cli-alpine-v2 php -m
```

### User and Permissions

Both versions run as `appuser` (UID 1000) by default:

```bash
# Same user behavior
docker run --rm kingpin/php-docker:8.3-fpm-alpine-v2 whoami
# Output: appuser
```

## Common Migration Issues

### Issue: Container Won't Start

**Symptom:** Container exits immediately after starting.

**Solution:** Check if you're overriding the ENTRYPOINT. v2 uses `/init` as ENTRYPOINT:

```bash
# Don't do this with v2:
docker run --entrypoint /bin/sh kingpin/php-docker:8.3-fpm-alpine-v2

# Instead, use CMD:
docker run --rm kingpin/php-docker:8.3-fpm-alpine-v2 sh -c "php -v"
```

### Issue: Custom Scripts Not Running

**Symptom:** Custom initialization scripts don't execute.

**Solution:** v2 uses s6-overlay's init hooks. Place scripts in:
- `/etc/cont-init.d/` - Run at container start (one-time)
- `/etc/services.d/{service}/run` - Service supervision scripts

Example Dockerfile:

```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine-v2

# Add init script
COPY my-init-script.sh /etc/cont-init.d/99-my-init
RUN chmod +x /etc/cont-init.d/99-my-init
```

### Issue: Local Build Fails

**Symptom:** `the --mount option requires BuildKit`

**Solution:** Enable BuildKit:

```bash
# Option 1: Environment variable
DOCKER_BUILDKIT=1 docker build -f Dockerfile.v2 -t myapp:v2 .

# Option 2: Install buildx
docker buildx install
docker buildx build -f Dockerfile.v2 -t myapp:v2 .
```

### Issue: Process Not Properly Supervised

**Symptom:** Background processes die and don't restart.

**Solution:** Create an s6 service definition:

```bash
# Create service directory
mkdir -p s6-services/myworker

# Create run script
cat > s6-services/myworker/run <<'EOF'
#!/usr/bin/with-contenv sh
exec php /var/www/html/artisan queue:work
EOF

chmod +x s6-services/myworker/run
```

Then in your Dockerfile:

```dockerfile
FROM kingpin/php-docker:8.3-fpm-alpine-v2
COPY s6-services/ /etc/services.d/
```

## Testing Your Migration

### Smoke Test Checklist

- [ ] Container starts successfully
- [ ] PHP version is correct: `docker run --rm IMAGE php -v`
- [ ] Extensions load: `docker run --rm IMAGE php -m`
- [ ] Application code runs: `docker run --rm -v $(pwd):/app IMAGE php /app/script.php`
- [ ] Writable directories work: `docker run --rm IMAGE sh -c "touch /tmp/test"`
- [ ] s6-overlay present: `docker run --rm IMAGE ls /etc/s6-overlay`
- [ ] Environment variables apply: `docker run --rm -e PHP_MEMORY_LIMIT=1G IMAGE php -i | grep memory_limit`

### Load Testing

Run load tests against both v1 and v2 to compare:

```bash
# Example with Apache Bench
ab -n 10000 -c 100 http://localhost/
```

Compare:
- Response times
- Error rates
- Memory usage
- CPU usage

## Rollback Plan

If you encounter issues, rolling back is simple:

```yaml
# Change tag back to v1
services:
  php-fpm:
    image: kingpin/php-docker:8.3-fpm-alpine  # Remove -v2 suffix
```

Then redeploy:

```bash
docker-compose pull
docker-compose up -d
```

## Getting Help

If you encounter migration issues:

1. Check [troubleshooting guide](troubleshooting.md)
2. Review [s6-overlay documentation](https://github.com/just-containers/s6-overlay)
3. Open an issue on GitHub with:
   - v1 tag you're migrating from
   - v2 tag you're migrating to
   - Error messages or unexpected behavior
   - Your docker-compose.yml or Dockerfile

## Next Steps

After successful migration:

- Review [s6-overlay documentation](https://github.com/just-containers/s6-overlay) for advanced features
- Consider adding custom services for background processes
- Optimize s6 service policies for your use case
- Update your team's documentation and runbooks
