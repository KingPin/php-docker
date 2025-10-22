# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed - v2 Images Only

- **BREAKING (Minor)**: v2 Debian images now built on **Debian Trixie** instead of Bookworm
  - Aligns with upstream PHP official image base OS migration
  - Provides access to newer system packages and security updates
  - **Backward Compatible**: `:bookworm` tags continue to work as aliases to Trixie-built images
  - **No Action Required** for most users - existing tags work transparently
  - v1 images remain on Debian Bookworm (no change)
  - See [Migration Guide](docs/migration.md#debian-trixie-migration-v2-only) for details

### Added

- Support for Debian Trixie base OS in v2 images
- Automatic `:bookworm` tag aliasing for v2 Trixie-built images (backward compatibility)
- Updated system libraries with time64 support (`t64` suffix packages)
- Comprehensive migration documentation for Trixie base OS change

### Technical Details

- Updated `Dockerfile.v2` to handle both Trixie and Bookworm base OS values
- Library updates for Trixie time64 transition:
  - `libpng16-16t64`, `libmagickwand-6.q16-7t64`, `libvips42t64`
  - `libavif16t64`, `libmemcached11t64`, `libsnmp40t64`
- CI workflows updated to build v2 on Trixie matrix
- Added `docker buildx imagetools create` step to publish bookworm compatibility tags

## Previous Releases

See git history for earlier changes.
