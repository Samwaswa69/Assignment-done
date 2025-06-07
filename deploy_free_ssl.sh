#!/bin/bash

echo "[+] Stopping any existing container..."
docker stop assignment-container 2>/dev/null || true
docker rm assignment-container 2>/dev/null || true

echo "[+] Building Docker image from GitHub source..."
docker build -t assignment-image .

echo "[+] Running Docker container on port 80..."
docker run -d --name assignment-container -p 80:80 assignment-image

echo "[✓] Deployment complete. Site should be live at: http://207.180.211.224"
