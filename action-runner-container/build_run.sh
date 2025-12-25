#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <GITHUB_URL> <GITHUB_TOKEN>"
    echo "Follow the github runner setup instructions to get the URL and token."
    exit 1
fi

GITHUB_URL="$1"
GITHUB_TOKEN="$2"

echo "Building Docker image..."
docker build -t actions-runner .

echo "Running container..."
docker run -d \
    -e GITHUB_URL="$GITHUB_URL" \
    -e GITHUB_TOKEN="$GITHUB_TOKEN" \
    actions-runner

echo "Container started successfully!"
