# Local Development & Building

Guide for building and testing PHP Docker images locally.

## Prerequisites

- Docker 20.10+ with BuildKit support
- For v2 images: Docker buildx plugin
- Git

### Installing BuildKit/Buildx

**Check if buildx is installed:**
```bash
docker buildx version
```

**If not installed:**
```bash
# Download and install buildx
docker buildx install

# Verify installation
docker buildx version
```

## Quick Start: test-build.sh

The repository includes a helper script for building images locally.

### Basic Usage

```bash
# Build v1 variant
./test-build.sh v1 8.3-fpm-alpine

# Build v2 variant
./test-build.sh v2 8.3-fpm-alpine

# Build both variants
./test-build.sh both 8.3-fpm-alpine
```

### How It Works

The script automatically:
- Parses the tag (e.g., `8.3-fpm-alpine`) to extract:
  - PHP version: `8.3`
  - PHP type: `fpm`
  - Base OS: `alpine`
- Passes these as build arguments
- Appends `-v2` suffix for v2 builds
- Enables BuildKit for v2 builds

### Examples

```bash
# Build different PHP versions
./test-build.sh v2 8.1-cli-alpine
./test-build.sh v2 8.2-fpm-bookworm
./test-build.sh v2 8.3-apache-bookworm

# Build both v1 and v2
./test-build.sh both 8.3-cli-alpine
```

### Testing Built Images

After building, test your images:

```bash
# Check PHP version
docker run --rm php-docker:8.3-fpm-alpine-v2 php -v

# List extensions
docker run --rm php-docker:8.3-fpm-alpine-v2 php -m

# Check s6-overlay (v2 only)
docker run --rm php-docker:8.3-fpm-alpine-v2 ls -la /etc/s6-overlay

# Interactive shell
docker run --rm -it php-docker:8.3-cli-alpine-v2 sh
```

## Manual Building

### Building v1 Images

v1 images use standard Docker build:

```bash
docker build \
  -f Dockerfile.v1 \
  --build-arg VERSION=8.3-fpm-alpine \
  --build-arg PHPVERSION=8.3 \
  --build-arg BASEOS=alpine \
  -t php-docker:8.3-fpm-alpine \
  .
```

### Building v2 Images

v2 images require BuildKit:

```bash
# Option 1: Environment variable
DOCKER_BUILDKIT=1 docker build \
  -f Dockerfile.v2 \
  --build-arg VERSION=8.3-fpm-alpine \
  --build-arg PHPVERSION=8.3 \
  --build-arg BASEOS=alpine \
  -t php-docker:8.3-fpm-alpine-v2 \
  .

# Option 2: Using buildx
docker buildx build \
  -f Dockerfile.v2 \
  --build-arg VERSION=8.3-fpm-alpine \
  --build-arg PHPVERSION=8.3 \
  --build-arg BASEOS=alpine \
  --load \
  -t php-docker:8.3-fpm-alpine-v2 \
  .
```

## Build Arguments

Both Dockerfile.v1 and Dockerfile.v2 accept these build arguments:

| Argument | Description | Example |
|----------|-------------|---------|
| `VERSION` | Full version string | `8.3-fpm-alpine` |
| `PHPVERSION` | PHP version only | `8.3` |
| `BASEOS` | Base OS | `alpine` or `bookworm` |

## Running Smoke Tests Locally

### Basic Smoke Tests

```bash
IMAGE="php-docker:8.3-fpm-alpine-v2"

# Test 1: PHP version
docker run --rm $IMAGE php -v

# Test 2: PHP CLI execution
docker run --rm $IMAGE php -r "echo 'Hello World';"

# Test 3: List extensions
docker run --rm $IMAGE php -m

# Test 4: Check writable directories
docker run --rm $IMAGE sh -c "test -w /tmp && echo '/tmp writable'"
docker run --rm $IMAGE sh -c "test -w /var/www && echo '/var/www writable'"
```

### v2-Specific Tests

```bash
IMAGE="php-docker:8.3-fpm-alpine-v2"

# Test 5: s6-overlay presence
docker run --rm $IMAGE test -d /etc/s6-overlay && echo "s6-overlay present"

# Test 6: Init binary
docker run --rm $IMAGE test -f /init && echo "s6 init present"

# Test 7: Run with s6 init
docker run --rm $IMAGE php -r "echo 'Running via s6 init';"
```

### FPM-Specific Tests

```bash
# Test PHP-FPM
docker run --rm php-docker:8.3-fpm-alpine-v2 php-fpm --version

# Start FPM and test
docker run -d --name test-fpm -p 9000:9000 php-docker:8.3-fpm-alpine-v2
sleep 2
docker logs test-fpm
docker stop test-fpm
docker rm test-fpm
```

## Multi-Architecture Builds

### Building for Multiple Architectures

```bash
# Create buildx builder
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
  -f Dockerfile.v2 \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --build-arg VERSION=8.3-fpm-alpine \
  --build-arg PHPVERSION=8.3 \
  --build-arg BASEOS=alpine \
  -t php-docker:8.3-fpm-alpine-v2 \
  .

# Remove builder when done
docker buildx rm multiarch
```

## Customizing Images

### Adding Custom Extensions

Create a custom Dockerfile:

```dockerfile
FROM php-docker:8.3-fpm-alpine-v2

# Install additional extensions
RUN install-php-extensions \
    swoole \
    pcntl \
    xdebug

# Add custom PHP config
COPY custom-php.ini /usr/local/etc/php/conf.d/custom.ini
```

Build it:
```bash
docker build -t my-custom-php:latest .
```

### Adding s6 Services (v2 only)

```bash
# Create service directory structure
mkdir -p s6-services/worker

# Create run script
cat > s6-services/worker/run <<'EOF'
#!/usr/bin/with-contenv sh
echo "Starting background worker..."
exec php /var/www/html/worker.php
EOF

chmod +x s6-services/worker/run
```

Dockerfile:
```dockerfile
FROM php-docker:8.3-fpm-alpine-v2
COPY s6-services/ /etc/services.d/
```

## Development Workflow

### Typical Development Cycle

1. **Make changes** to Dockerfile.v1 or Dockerfile.v2
2. **Build locally** using `test-build.sh`
3. **Run smoke tests** to verify functionality
4. **Test your application** with the new image
5. **Commit changes** and push to GitHub
6. **CI pipeline** will run automated tests

### Testing Changes

```bash
# Build both variants
./test-build.sh both 8.3-fpm-alpine

# Run quick tests
for variant in "" "-v2"; do
  echo "Testing php-docker:8.3-fpm-alpine$variant"
  docker run --rm php-docker:8.3-fpm-alpine$variant php -v
  docker run --rm php-docker:8.3-fpm-alpine$variant php -m | wc -l
done
```

## Troubleshooting Build Issues

### Build Cache Issues

Clear build cache:
```bash
# Clear Docker build cache
docker builder prune -a

# For buildx
docker buildx prune -a
```

### BuildKit Not Available

```bash
# Check Docker version
docker version

# Update Docker if needed (20.10+ required)
# Or install buildx plugin
docker buildx install
```

### Out of Disk Space

```bash
# Clean up Docker system
docker system prune -a --volumes

# Check disk usage
docker system df
```

### Slow Builds

```bash
# Enable BuildKit cache
docker buildx build \
  --cache-from type=local,src=/tmp/docker-cache \
  --cache-to type=local,dest=/tmp/docker-cache,mode=max \
  ...
```

## CI/CD Integration

For CI/CD pipelines, see [docs/ci.md](ci.md) for:
- GitHub Actions workflow configuration
- Publishing to multiple registries
- Automated testing and scanning

## Additional Resources

- [Docker BuildKit documentation](https://docs.docker.com/build/buildkit/)
- [Buildx documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [s6-overlay documentation](https://github.com/just-containers/s6-overlay)
- [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/)
