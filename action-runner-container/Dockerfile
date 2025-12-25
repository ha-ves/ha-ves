FROM ubuntu:latest

WORKDIR /home/runner

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download the latest actions-runner
RUN curl -o actions-runner-linux-x64-2.330.0.tar.gz -L \
    https://github.com/actions/runner/releases/download/v2.330.0/actions-runner-linux-x64-2.330.0.tar.gz && \
    tar xzf ./actions-runner-linux-x64-2.330.0.tar.gz && \
    rm actions-runner-linux-x64-2.330.0.tar.gz

# Environment variables for runtime configuration
ENV GITHUB_URL=""
ENV GITHUB_TOKEN=""

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ -z "$GITHUB_URL" ] || [ -z "$GITHUB_TOKEN" ]; then\n\
    echo "Error: GITHUB_URL and GITHUB_TOKEN must be provided"\n\
    exit 1\n\
fi\n\
./config.sh --url "$GITHUB_URL" --token "$GITHUB_TOKEN" --unattended --replace\n\
./run.sh' > /home/runner/entrypoint.sh && \
    chmod +x /home/runner/entrypoint.sh

# Run the runner
CMD ["/home/runner/entrypoint.sh"]
