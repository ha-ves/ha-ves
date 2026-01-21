#!/bin/bash
set -euo pipefail

IMAGE_TAG="${1:-action-runner:latest}"
CONTAINER_NAME="${2:-action-runner}"
HOST_SOCKET_PATH="${3:-/run/podman/podman.sock}"
CONTAINER_SOCKET_PATH="/run/podman/podman.sock"

# Usage: run_runner.sh [IMAGE_TAG] [CONTAINER_NAME] [HOST_SOCKET_PATH]
# Example: ./run_runner.sh action-runner:latest my-runner /run/podman/podman.sock

echo "Running container $CONTAINER_NAME from image $IMAGE_TAG (mounts host podman socket $HOST_SOCKET_PATH to $CONTAINER_SOCKET_PATH)"
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -v "$HOST_SOCKET_PATH:$CONTAINER_SOCKET_PATH" \
  "$IMAGE_TAG"

echo "Container started successfully!"
