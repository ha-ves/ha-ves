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

# If configured already (marker file), just start the runner
if [ -f "$RUNNER_DIR/.configured" ]; then
  echo "Runner already configured (found .configured), starting run.sh"
  cleanup_stale_state
  touch "$RUNNER_DIR/.running"
  exec ./run.sh
fi

# First-time configuration: require a registration token and URL
if [ -z "$GITHUB_URL" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$PODMAN_SERVICE" ]; then
  echo "GITHUB_URL, GITHUB_TOKEN, and PODMAN_SERVICE are required for initial configuration"
  echo "Set those env vars for first run, then restart without them."
  exit 1
fi

cleanup_stale_state

echo "Configuring runner for $GITHUB_URL"
if ./config.sh $CONFIG_ARGS --unattended --url "$GITHUB_URL" --token "$GITHUB_TOKEN" --replace; then
  # create a simple marker so subsequent container starts skip config
  touch "$RUNNER_DIR/.configured"
  echo "Configuration complete — created $RUNNER_DIR/.configured"
  touch "$RUNNER_DIR/.running"
  exec ./run.sh
else
  echo "Configuration failed"
  exit 1
fi
