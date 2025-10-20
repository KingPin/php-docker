# CI/CD & Publishing

Information about the automated build, test, and publishing pipeline.

## Overview

This repository uses GitHub Actions to automatically build, test, and publish Docker images.

### Pipeline Behavior

- **All branches and PRs**: Build and test only (no publishing)
- **`main` branch only**: Build, test, **and publish** to registries

This ensures that only tested, approved changes make it to production registries.

## Workflow: docker-ci.yml

The unified CI workflow handles both v1 and v2 variants in a single pipeline.

### Jobs

#### 1. build-and-test

Runs on every push and pull request:

```yaml
matrix:
  variant: [v1, v2]
  php-version: ['8.3', '8.1']
  php-type: [fpm, cli]
  php-base: [alpine, bookworm]
```

**What it does:**
- Builds both v1 and v2 images
- Runs comprehensive smoke tests:
  - PHP version verification
  - Extension checks
  - Directory permissions
  - v2: s6-overlay validation
  - FPM: PHP-FPM functionality
- Uses GitHub Actions cache for faster builds
- Fails fast if any variant fails

#### 2. publish

Runs **only on `main` branch** after successful build-and-test:

```yaml
matrix:
  variant: [v1, v2]
  php-version: ['8.3', '8.2', '8.1', '7']
  php-type: [fpm, cli, apache]
  php-base: [alpine, bookworm, bullseye]
```

**What it does:**
- Builds multi-architecture images (amd64, arm64, arm/v7)
- Publishes to three registries:
  - Docker Hub: `docker.io/kingpin/php-docker`
  - GitHub Container Registry: `ghcr.io/kingpin/php-docker`
  - Quay.io: `quay.io/kingpinx1/php-docker`
- Runs Trivy security scanner
- Uploads SARIF results to GitHub Security

## Required Secrets

To enable publishing, configure these GitHub repository secrets:

| Secret | Description | Used For |
|--------|-------------|----------|
| `DOCKERHUB_USERNAME` | Docker Hub username | Docker Hub login |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Docker Hub authentication |
| `QUAY_USERNAME` | Quay.io username | Quay.io login |
| `QUAY_ROBOT_TOKEN` | Quay.io robot account token | Quay.io authentication |

**Note:** `GITHUB_TOKEN` is automatically provided by GitHub Actions for GHCR.

### Setting Up Secrets

1. Go to repository **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add each secret with its value
4. Ensure secrets are available to workflows

## Manual Workflows

Two legacy workflows exist for manual triggering:

- `docker-image.v1.yml` - Build v1 images manually
- `docker-image.v2.yml` - Build v2 images manually

These run only via `workflow_dispatch` (manual trigger) and don't publish automatically.

## Branch Protection

**Recommended settings for `main` branch:**

1. **Require pull request reviews**: At least 1 approval
2. **Require status checks**: 
   - `build-and-test` must pass
   - All matrix jobs must succeed
3. **Require branches to be up to date**: Enable
4. **Restrict who can push**: Limit to maintainers

This prevents accidental publishing of broken images.

## Testing in CI

### PR Testing

When you open a PR, CI will:
1. Build all matrix combinations
2. Run smoke tests on each variant
3. Report pass/fail status
4. **Will NOT publish** images

### Branch Testing

Pushing to any branch (not just `main`) will:
1. Trigger build-and-test job
2. Run all smoke tests
3. **Will NOT publish** images

Only merging to `main` triggers publishing.

## Security Scanning

Every published image is scanned with Trivy:

```yaml
- uses: aquasecurity/trivy-action@master
  with:
    scan-type: image
    severity: 'CRITICAL,HIGH'
    format: 'sarif'
```

Results appear in:
- GitHub Security tab
- PR checks (if scanning fails)

## Cache Strategy

The workflow uses GitHub Actions cache to speed up builds:

```yaml
cache-from: type=gha,scope=${{ matrix.variant }}-...
cache-to: type=gha,mode=max,scope=${{ matrix.variant }}-...
```

Benefits:
- Faster builds (layer caching)
- Reduced CI minutes
- Per-variant cache isolation

## Publishing Flow

When changes merge to `main`:

1. **Build-and-test runs** (all variants)
2. If all tests pass → **Publish job starts**
3. For each matrix combination:
   - Build multi-arch image
   - Tag for all three registries
   - Push to Docker Hub, GHCR, and Quay.io
   - Run Trivy scan
   - Upload security results
4. Images available within ~15-20 minutes

## Tag Management

Published tags follow this format:

**v1:** `{php-version}-{type}-{os}`  
**v2:** `{php-version}-{type}-{os}-v2`

Examples:
- `8.3-fpm-alpine` (v1)
- `8.3-fpm-alpine-v2` (v2)
- `8.2-cli-bookworm` (v1)
- `8.2-cli-bookworm-v2` (v2)

No `:latest` tag is currently published to avoid ambiguity.

## Monitoring Builds

### GitHub Actions Tab

View workflow runs:
1. Go to repository **Actions** tab
2. Select **Docker CI (v1 + v2)** workflow
3. Click any run to see details
4. Check individual job logs for debugging

### Build Status Badge

The README includes a status badge:

```markdown
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/kingpin/php-docker/docker-ci.yml?branch=main)](https://github.com/kingpin/php-docker/actions/workflows/docker-ci.yml)
```

Shows current build status for `main` branch.

## Troubleshooting CI Issues

### Build Fails on PRs

**Check:**
- Error messages in job logs
- Smoke test failures
- Build argument issues

**Common fixes:**
- Ensure Dockerfile syntax is correct
- Verify build args are passed correctly
- Check if extensions install properly

### Publish Fails on Main

**Check:**
- Registry secrets are configured
- Secrets have correct permissions
- Registry quotas/limits not exceeded

**Common fixes:**
- Regenerate registry tokens
- Verify secret names match workflow
- Check registry status pages

### Slow CI Runs

**Optimize:**
- Cache is working (check logs for "cache hit")
- Reduce matrix size for PRs if needed
- Use buildx cache features

## Contributing to CI

When modifying workflows:

1. Test changes in a fork first
2. Use small matrix for initial testing
3. Verify secrets aren't exposed in logs
4. Update this documentation

## Additional Resources

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Docker build-push-action](https://github.com/docker/build-push-action)
- [Trivy scanner](https://github.com/aquasecurity/trivy)
- [GitHub SARIF support](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning)
