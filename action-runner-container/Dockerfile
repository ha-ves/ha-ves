FROM ubuntu:latest

# Base image for GitHub Actions Runner with registration
# Includes all dependencies, runner installation, and configuration

# Build arguments for runner registration
ARG RUNNER_TOKEN
ARG RUNNER_URL=https://github.com/ha-ves/ha-ves
ARG RUNNER_NAME

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    jq \
    podman-remote \
    podman-docker \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for the runner
RUN useradd -s /bin/bash -d /runner -m runner


# Download and install the GitHub Actions Runner (v2.331.0)
RUN wget https://github.com/actions/runner/releases/download/v2.331.0/actions-runner-linux-x64-2.331.0.tar.gz -O - | tar xz --no-same-owner --directory /runner -f -

WORKDIR /runner

# Install runner dependencies
RUN ./bin/installdependencies.sh

# Switch to non-root user for runner registration and execution
USER runner
# Register runner with GitHub (non-interactive)
RUN ./config.sh --unattended --url ${RUNNER_URL} --token ${RUNNER_TOKEN} --name ${RUNNER_NAME}

# Add entrypoint script for running
USER root
COPY entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh
USER runner

# Entrypoint handles runner execution
# To pass host podman socket, mount at runtime:
# docker run -v /run/podman/podman.sock:/run/podman/podman.sock action-runner:latest
ENTRYPOINT ["/home/runner/entrypoint.sh"]
