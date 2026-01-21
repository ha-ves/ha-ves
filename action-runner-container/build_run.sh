#!/bin/bash
set -euo pipefail

# Usage: build_run.sh <RUNNER_URL> <RUNNER_TOKEN> [IMAGE_TAG] [RUNNER_NAME]
# Example: ./build_run.sh https://github.com/ha-ves/ha-ves mytoken action-runner:latest my-runner

RUNNER_URL="${1:-${RUNNER_URL:-https://github.com/ha-ves/ha-ves}}"
RUNNER_TOKEN="${2:-${RUNNER_TOKEN:-}}"
IMAGE_TAG="${3:-action-runner:latest}"
RUNNER_NAME="${4:-${RUNNER_NAME:-}}"

if [ -z "$RUNNER_TOKEN" ]; then
        echo "Error: RUNNER_TOKEN is required"
        echo "Usage: $0 <RUNNER_URL> <RUNNER_TOKEN> [IMAGE_TAG] [RUNNER_NAME]"
        exit 1
fi

echo "Building Docker image: $IMAGE_TAG"
docker build \
    --build-arg RUNNER_TOKEN="$RUNNER_TOKEN" \
    --build-arg RUNNER_URL="$RUNNER_URL" \
    --build-arg RUNNER_NAME="$RUNNER_NAME" \
    -t "$IMAGE_TAG" .

echo "Build complete. To run the container, use:"
echo "  docker run -d --name action-runner --restart unless-stopped -v /run/podman/podman.sock:/run/podman/podman.sock $IMAGE_TAG"
