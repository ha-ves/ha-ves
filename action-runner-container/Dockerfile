FROM ubuntu:latest

# Environment variables for runtime configuration
ENV GITHUB_URL="" \
    GITHUB_TOKEN="" \
    CONFIG_ARGS="" \
    PODMAN_SERVICE=""

# Install dependencies
RUN apt update && apt install -y --no-install-recommends ca-certificates git jq podman-remote wget

# Create a non-root user
RUN useradd -s /bin/bash -d /runner -m runner

RUN wget https://github.com/actions/runner/releases/download/v2.330.0/actions-runner-linux-x64-2.330.0.tar.gz -O - | tar xz --no-same-owner --directory /runner -f -

WORKDIR /runner

RUN ./bin/installdependencies.sh

# Add entrypoint script
COPY entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

USER runner

# Run the runner
ENTRYPOINT ["/home/runner/entrypoint.sh"]
