# Deprecated PHP Docker Images

This document lists PHP versions that are **no longer actively built** but remain available in container registries for backwards compatibility.

## ⚠️ Important Notice

- **No new builds** will be published for these versions
- **No security updates** will be applied to these images
- **Existing images remain available** for download from Docker Hub, GHCR, and Quay.io
- **Migration is strongly recommended** for production workloads

## Deprecated Versions

### PHP 7.x (All Variants)

**Status**: End of Life - No longer maintained by PHP project  
**Last Build**: January 2025  
**Reason**: PHP 7.4 reached end-of-life November 2022

#### Available Tags (Legacy)

**Alpine-based:**
- `7-cli-alpine`
- `7-fpm-alpine`
- `7-cli-alpine-v2`
- `7-fpm-alpine-v2`

**Debian Bullseye-based:**
- `7-cli-bullseye`
- `7-fpm-bullseye`
- `7-apache-bullseye`
- `7-cli-bullseye-v2`
- `7-fpm-bullseye-v2`
- `7-apache-bullseye-v2`

**Architectures**: linux/amd64, linux/arm64, linux/arm/v7

### PHP 8.1 (All Variants)

**Status**: End of Active Support (security-only updates until Nov 2025)  
**Last Build**: January 2025  
**Reason**: Focus maintenance on PHP 8.2+ for better resource allocation

#### Available Tags (Legacy)

**Alpine-based:**
- `8.1-cli-alpine`
- `8.1-fpm-alpine`
- `8.1-cli-alpine-v2`
- `8.1-fpm-alpine-v2`

**Debian Bookworm-based:**
- `8.1-cli-bookworm`
- `8.1-fpm-bookworm`
- `8.1-apache-bookworm`
- `8.1-cli-bookworm-v2`
- `8.1-fpm-bookworm-v2`
- `8.1-apache-bookworm-v2`

**Architectures**: linux/amd64, linux/arm64, linux/arm/v7

## Migration Recommendations

### From PHP 7.x → PHP 8.2 or 8.3

**Breaking Changes to Consider:**
- Deprecated features removed in PHP 8.0+
- Stricter type handling
- Changes to error reporting
- Removed legacy extensions

**Steps:**
1. Review [PHP 8 migration guide](https://www.php.net/manual/en/migration80.php)
2. Test your application locally with PHP 8.2 or 8.3
3. Update dependencies in `composer.json`
4. Run automated tests
5. Update Docker image tags

**Example:**
```bash
# Old (deprecated)
docker pull kingpin/php-docker:7-fpm-alpine

# New (recommended)
docker pull kingpin/php-docker:8.3-fpm-alpine
```

### From PHP 8.1 → PHP 8.2 or 8.3

**Breaking Changes:**
- PHP 8.2: Deprecated dynamic properties
- PHP 8.3: More readonly class features

**Steps:**
1. Review [PHP 8.2 migration guide](https://www.php.net/manual/en/migration82.php) or [PHP 8.3 guide](https://www.php.net/manual/en/migration83.php)
2. Update image tags in your deployment manifests
3. Test thoroughly in staging environment
4. Deploy to production

**Example:**
```bash
# Old (deprecated)
docker pull kingpin/php-docker:8.1-fpm-alpine

# New (recommended)
docker pull kingpin/php-docker:8.3-fpm-alpine
```

### Docker Compose Migration

```yaml
# Before (deprecated)
services:
  app:
    image: kingpin/php-docker:8.1-fpm-alpine

# After (recommended)
services:
  app:
    image: kingpin/php-docker:8.3-fpm-alpine
```

### Kubernetes/Helm Migration

```yaml
# Before (deprecated)
containers:
  - name: app
    image: kingpin/php-docker:8.1-fpm-alpine

# After (recommended)
containers:
  - name: app
    image: kingpin/php-docker:8.3-fpm-alpine
```

## Long-Term Availability

### Registry Retention

These deprecated images will remain available **indefinitely** in the following registries:
- **Docker Hub**: hub.docker.com/r/kingpin/php-docker
- **GitHub Container Registry**: ghcr.io/kingpin/php-docker
- **Quay.io**: quay.io/kingpinx1/php-docker

### Pulling Deprecated Images

You can continue to pull these images as normal:

```bash
# PHP 7.x example
docker pull kingpin/php-docker:7-fpm-alpine

# PHP 8.1 example
docker pull kingpin/php-docker:8.1-fpm-alpine
```

### Security Considerations

**Important**: Deprecated images will NOT receive:
- Security patches for PHP vulnerabilities
- Updates to bundled system packages
- Updates to PHP extensions
- Bug fixes

**For production use**, we strongly recommend migrating to actively supported versions (PHP 8.2 or 8.3).

## Support Policy

- **Active Builds**: PHP 8.2 and 8.3 (receive regular updates)
- **Deprecated**: PHP 7.x and 8.1 (images frozen, no updates)
- **Removed**: None (all previously published images remain available)

## Image Digests (Last Published)

For reproducible builds, you can pin to specific digests. Contact the maintainer or check registry APIs for exact digest values of the last published builds.

Example of digest pinning:
```bash
# Pin to specific digest (immutable)
docker pull kingpin/php-docker@sha256:abcdef1234567890...
```

## Questions or Issues?

If you need assistance migrating from deprecated versions:

1. Check the [migration guide](migration.md)
2. Review [troubleshooting guide](troubleshooting.md)
3. Open an issue on GitHub with:
   - Current deprecated version you're using
   - Target version you want to migrate to
   - Specific migration challenges

## Timeline

- **November 2024**: Announcement of deprecation plan
- **January 2025**: Last builds for PHP 7.x and 8.1
- **Ongoing**: Images remain available in registries indefinitely

---

Last updated: January 2025
