# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-architecture PHP Docker image builder. Two parallel Dockerfile variants (v1 and v2) produce images for PHP 8.2, 8.3, 8.4, 8.5 across alpine/bookworm (v1) and alpine/trixie (v2), with fpm and cli types. Published to Docker Hub, GHCR, and Quay.io.

Deprecation policy: PHP versions are removed from the build matrix when upstream security support ends ([php.net schedule](https://www.php.net/supported-versions.php)). PHP 8.2 is scheduled for removal after 2026-12-31.

## Local Build Commands

```bash
# Build a single image locally
./extras/test-build.sh v1 8.3-fpm-alpine
./extras/test-build.sh v2 8.3-fpm-alpine    # tags as php-docker:8.3-fpm-alpine-v2
./extras/test-build.sh both 8.3-fpm-alpine   # builds both variants

# v2 requires BuildKit (test-build.sh sets DOCKER_BUILDKIT=1 automatically)

# Smoke test installed extensions
docker run --rm php-docker:8.3-fpm-alpine php /extras/php_test.php
```

Tag format: `<php-version>-<type>-<baseos>` (e.g., `8.4-cli-trixie`, `8.2-fpm-bookworm`).

Build args used by both Dockerfiles: `VERSION`, `PHPVERSION`, `BASEOS`.

## CI/CD

Primary workflow: `.github/workflows/docker-ci.yml` — runs on push to main, PRs, weekly schedule (Tuesday 3 AM UTC), and `workflow_dispatch`. Uses a build matrix across all variant/version/type/base combinations with `fail-fast: false`.

Key matrix rules:
- v1 uses bookworm for Debian; v2 uses trixie
- No apache type on alpine
- Multi-arch production builds: linux/amd64, linux/arm64, linux/arm/v7
- PR fast-path tests only newest + oldest PHP versions (currently 8.5 + 8.2); push/schedule runs the full matrix

## Architecture: v1 vs v2

**v1 (Dockerfile.v1)**: Simple single-stage build. No init system. Base images from ECR (`public.ecr.aws/docker/library/php`). Suited for single-process containers.

**v2 (Dockerfile.v2)**: s6-overlay v3.2.1.0 for process supervision. OCI labels. Handles Debian Trixie t64 library transitions. BuildKit required. Production multi-process workloads.

Both install 30+ PHP extensions via `install-php-extensions` (with retry/backoff logic) and include Composer, image optimization tools (gifsicle, jpegoptim, optipng, pngquant).

## s6-overlay (v2 only)

- `s6-overlay/cont-init.d/10-php-config` — applies PHP config from environment variables (PHP_MEMORY_LIMIT, PHP_UPLOAD_MAX_FILESIZE, etc.)
- `s6-overlay/services.d/php/run` — auto-detects and starts php-fpm, apache, or sleep for cli
- `s6-overlay/services.d/php/finish` — graceful shutdown

## Platform-Specific Gotchas

- ARM/v7: GD built without AVIF support (no AV1 on armv7)
- Trixie (v2): requires t64 library name handling (`libavif-dev` vs `libavif-devt64`)
- ECR base images preferred over Docker Hub to avoid rate limits
- install-php-extensions download has retry logic with exponential backoff

## Documentation Checks

`docs-ci.yml` validates markdown links on changes to `**.md` or `docs/**`. Config in `.github/markdown-link-check-config.json`.
