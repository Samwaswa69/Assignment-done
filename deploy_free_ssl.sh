#!/bin/bash

# --- Configuration ---
VPS_IP="207.180.211.224"
IMAGE_NAME="my-static-site"
CONTAINER_NAME="my-nginx-site"
GIT_REPO_URL="git@github.com:Samwaswa69/Assignment-done.git"
# Directory where the Git repository will be cloned
CLONE_DIR="Assignment-done_repo" # Name of the cloned directory

# --- Pre-checks ---
if ! command -v docker &> /dev/null
then
    echo "Error: Docker is not installed. Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v openssl &> /dev/null
then
    echo "Error: OpenSSL is not installed. Please install OpenSSL."
    exit 1
fi

if ! command -v git &> /dev/null
then
    echo "Error: Git is not installed. Please install Git."
    exit 1
fi

# --- Step 1: Clone or Update Git Repository ---
echo "--- Cloning/Updating Git repository: $GIT_REPO_URL ---"
if [ -d "$CLONE_DIR" ]; then
    echo "Repository directory '$CLONE_DIR' already exists. Pulling latest changes..."
    cd "$CLONE_DIR" || { echo "Error: Could not change directory to '$CLONE_DIR'."; exit 1; }
    git pull || { echo "Error: Git pull failed."; exit 1; }
    cd .. # Go back to the parent directory
else
    git clone "$GIT_REPO_URL" "$CLONE_DIR" || { echo "Error: Git clone failed. Check SSH key setup or repository URL."; exit 1; }
fi
echo "Repository '$CLONE_DIR' is up to date."
echo ""

# --- Navigate into the cloned directory for subsequent operations ---
cd "$CLONE_DIR" || { echo "Error: Could not navigate into cloned repository '$CLONE_DIR'."; exit 1; }

# --- Step 2: Generate Self-Signed SSL Certificate ---
# Assuming 'certs/' directory and your static files ('html/', 'nginx.conf', 'Dockerfile') are inside the cloned repo
CERT_DIR="certs"
echo "--- Generating self-signed SSL certificate ---"
mkdir -p "$CERT_DIR"

# Check if certificates already exist to avoid re-generating unnecessarily
if [ ! -f "$CERT_DIR/selfsigned.key" ] || [ ! -f "$CERT_DIR/selfsigned.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/selfsigned.key" \
        -out "$CERT_DIR/selfsigned.crt" \
        -subj "/CN=$VPS_IP"
    echo "SSL certificate and key generated in '$CERT_DIR/' inside the cloned repo."
else
    echo "SSL certificate and key already exist in '$CERT_DIR/'. Skipping generation."
fi
echo ""

# --- Step 3: Build the Docker Image ---
echo "--- Building Docker image: $IMAGE_NAME ---"
# Build from the context of the cloned repository
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "Error: Docker image build failed. Exiting."
    # Exit from the cloned directory to avoid permission issues later if the script is run again.
    cd ..
    exit 1
fi
echo "Docker image '$IMAGE_NAME' built successfully."
echo ""

# --- Step 4: Stop and Remove Existing Container (if any) ---
echo "--- Stopping and removing existing container (if any): $CONTAINER_NAME ---"
# Go back to the original directory before checking/managing containers
cd ..
if docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    echo "Existing container '$CONTAINER_NAME' stopped and removed."
else
    echo "No existing container '$CONTAINER_NAME' found."
fi
echo ""

# --- Step 5: Run the Docker Container ---
echo "--- Running Docker container: $CONTAINER_NAME ---"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p 80:80 \
    -p 443:443 \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to run Docker container. Check logs for details."
    exit 1
fi

echo "Docker container '$CONTAINER_NAME' is running!"
echo "You should now be able to access your site at: https://$VPS_IP"
echo "Remember to accept the self-signed certificate warning in your browser."
echo ""

# --- Optional: Show running containers ---
echo "--- Current running Docker containers ---"
docker ps

# --- Cleanup (Optional) ---
# If you want to remove the cloned repository after deployment, uncomment the lines below.
# rm -rf "$CLONE_DIR"
# echo "Cleaned up cloned repository directory '$CLONE_DIR'."
