# Migration Guide

This guide helps you migrate between different versions of php-docker images.

## Debian Trixie Migration (v2 only)

**Effective Date:** October 2025  
**Affects:** v2 Debian images only (v1 remains on Bookworm)

### What Changed

v2 Debian-based images have migrated from **Debian Bookworm** to **Debian Trixie** to align with upstream PHP official images and provide access to newer system packages.

**Important:** For backward compatibility, `:bookworm` tags continue to work and now point to Trixie-built images. The same image digest is served whether you pull `:trixie` or `:bookworm` tags.

### Tag Mapping

All v2 Debian images now use Trixie as the base, with multiple compatible tags:

```bash
# These all reference the SAME trixie-built image:
kingpin/php-docker:8.3-fpm-trixie-v2      # Explicit trixie tag
kingpin/php-docker:8.3-fpm-bookworm-v2    # Backward-compatible alias
kingpin/php-docker:8.3-fpm-bullseye-v2    # Legacy compatibility alias
```

### Why This Change?

1. **Upstream Alignment**: PHP official images moved to Trixie
2. **Newer Packages**: Access to latest system libraries and security updates
3. **Future-Proofing**: Trixie will become the next Debian stable release
4. **Zero Disruption**: Bookworm tags work transparently

### Do I Need to Change Anything?

**Short answer: No, in most cases.**

If you're currently using:
- `kingpin/php-docker:8.x-type-bookworm-v2` → **No action required**. You'll automatically get Trixie-built images.
- `kingpin/php-docker:8.x-type-alpine-v2` → **No change**. Alpine images are unaffected.
- v1 images (without `-v2`) → **No change**. v1 remains on Bookworm.

### When to Review Your Setup

✅ **Review if you:**
- Compile native extensions or link against system libraries in your application
- Have strict compliance requirements for a specific Debian version
- Use host-mounted volumes with binaries that depend on glibc versions
- Pin specific package versions via `apt-get install` in your Dockerfile layers

✅ **Testing checklist:**
1. Verify PHP version: `docker run --rm IMAGE php -v`
2. Check extensions load: `docker run --rm IMAGE php -m`
3. Test your application's core functionality
4. Run your test suite if available
5. Check for any compiled extensions (e.g., custom C extensions)

### Library Changes in Trixie

Key system library updates (time64 transition):

| Library | Bookworm | Trixie |
|---------|----------|--------|
| libpng | `libpng16-16` | `libpng16-16t64` |
| libmagickwand | `libmagickwand-6.q16-6` | `libmagickwand-6.q16-7t64` |
| libvips | `libvips42` | `libvips42t64` |
| libavif | `libavif15` | `libavif16t64` |
| libmemcached | `libmemcached11` | `libmemcached11t64` |

> **Note:** The `t64` suffix indicates [time64](https://wiki.debian.org/ReleaseGoals/64bit-time) support for 32-bit architectures. This does not affect x86_64 or arm64 users.

### Rollback Plan

If you encounter issues:

1. **Pin to a legacy Bookworm digest** (if you have one saved):
   ```bash
   # Use a specific digest from before the migration
   docker pull kingpin/php-docker@sha256:abc123...
   ```

2. **Use v1 images** (still on Bookworm):
   ```bash
   # v1 images remain on Debian Bookworm
   docker pull kingpin/php-docker:8.3-fpm-bookworm
   ```

3. **Report the issue**:
   - Open an issue: https://github.com/kingpin/php-docker/issues
   - Include: PHP version, image tag, error logs, and reproduction steps

### FAQ

**Q: Will my existing containers break?**  
A: No. Existing running containers continue unchanged. New pulls get Trixie-built images.

**Q: Can I explicitly use Bookworm-built images?**  
A: Use v1 images (without `-v2` suffix), which remain on Bookworm.

**Q: What about Alpine images?**  
A: Alpine images are completely unaffected by this change.

**Q: Will Trixie images be larger?**  
A: Image sizes are comparable. CI tests show negligible differences (<5%).

**Q: Is this breaking my compliance requirements?**  
A: If you require certified Bookworm images, use v1. v2 is built on Trixie going forward.

**Q: When will v1 move to Trixie?**  
A: No current plans. v1 remains on Bookworm for maximum stability and compatibility.

---

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
