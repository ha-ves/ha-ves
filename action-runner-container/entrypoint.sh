#!/bin/bash

set -e
RUNNER_DIR=/runner
cd "$RUNNER_DIR"

alias docker='podman-remote'

# Function to clean up stale running state
cleanup_stale_state() {
  if [ -f "$RUNNER_DIR/.running" ]; then
    echo "Found stale .running file, cleaning up..."
    echo "Attempting to kill any zombie runner processes..."
    pkill -f "Runner.Listener" || true
    pkill -f "run.sh" || true
    sleep 2
    rm -f "$RUNNER_DIR/.running"
  fi
}

# If docker CLI is available in the container but the Docker socket is not mounted,
# warn the user so they can bind-mount the host socket when running the container.
if command -v docker >/dev/null 2>&1 && [ ! -S "${DOCKER_SOCKET_PATH:-/var/run/docker.sock}" ]; then
  echo "Warning: docker CLI found but socket ${DOCKER_SOCKET_PATH:-/var/run/docker.sock} not present."
  echo "To enable Docker access, start the container with: -v /var/run/docker.sock:${DOCKER_SOCKET_PATH:-/var/run/docker.sock}"
fi

# Always just start the runner, no configuration
cleanup_stale_state
touch "$RUNNER_DIR/.running"
exec ./run.sh
