#!/bin/bash

REPO_URL="https://github.com/Samwaswa69/Assignment-done.git"
APP_DIR="/opt/assignment-site"
IMAGE_NAME="assignment-site"
CONTAINER_NAME="assignment-container"

# Clone or pull latest code
if [ -d "$APP_DIR/.git" ]; then
    echo "[+] Pulling latest code from GitHub..."
    cd "$APP_DIR" && git reset --hard HEAD && git pull origin main
else
    echo "[+] Cloning repo..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR" || exit 1
fi

# Stop and remove existing container if running
echo "[+] Stopping old container (if any)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Build new Docker image
echo "[+] Building Docker image from fresh source..."
cd "$APP_DIR" || exit 1
docker build --no-cache -t "$IMAGE_NAME" .

# Run the container
echo "[+] Running container on port 80..."
docker run -d --name "$CONTAINER_NAME" -p 80:80 "$IMAGE_NAME"

echo "[✓] Deployment complete: http://207.180.211.224"
