#!/usr/bin/env bash
set -e

# Usage: ./test-build.sh {v1|v2|both} <tag>
# Example: ./test-build.sh v1 8.3-fpm-alpine
# Example: ./test-build.sh v2 8.3-fpm-alpine  (builds as 8.3-fpm-alpine-v2)
# Example: ./test-build.sh both 8.3-fpm-alpine

IMAGE_NAME="php-docker"

show_usage() {
    echo "Usage: $0 {v1|v2|both} <tag>"
    echo ""
    echo "Arguments:"
    echo "  v1|v2|both  - Which Dockerfile variant(s) to build"
    echo "  <tag>       - Base tag (e.g., 8.3-fpm-alpine)"
    echo ""
    echo "Examples:"
    echo "  $0 v1 8.3-fpm-alpine           # Builds ${IMAGE_NAME}:8.3-fpm-alpine"
    echo "  $0 v2 8.3-fpm-alpine           # Builds ${IMAGE_NAME}:8.3-fpm-alpine-v2"
    echo "  $0 both 8.3-fpm-alpine         # Builds both variants"
    exit 1
}

build_v1() {
    local tag=$1
    echo "Building v1: ${IMAGE_NAME}:${tag}"
    docker build -f Dockerfile.v1 -t "${IMAGE_NAME}:${tag}" .
    echo "✓ Built ${IMAGE_NAME}:${tag}"
}

build_v2() {
    local tag=$1
    local v2_tag="${tag}-v2"
    echo "Building v2: ${IMAGE_NAME}:${v2_tag}"
    docker build -f Dockerfile.v2 -t "${IMAGE_NAME}:${v2_tag}" .
    echo "✓ Built ${IMAGE_NAME}:${v2_tag}"
}

# Check arguments
if [ $# -lt 2 ]; then
    show_usage
fi

VARIANT=$1
TAG=$2

case "$VARIANT" in
    v1)
        build_v1 "$TAG"
        ;;
    v2)
        build_v2 "$TAG"
        ;;
    both)
        build_v1 "$TAG"
        build_v2 "$TAG"
        ;;
    *)
        echo "Error: Invalid variant '$VARIANT'"
        echo ""
        show_usage
        ;;
esac

echo ""
echo "Build complete!"
