#!/bin/bash

# Env Vars
EMAIL="andymasa2animate@gmail.com" # not used now, kept for future domain use

# Script Vars
REPO_URL="git@github.com:Samwaswa69/Assignment-done.git"
APP_DIR=~/myapp
SWAP_SIZE="1G"
SSL_DIR="/etc/ssl/myapp"

# Update package list and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Add Swap Space
echo "Adding swap space..."
sudo fallocate -l $SWAP_SIZE /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Install Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
sudo apt update
sudo apt install -y docker-ce

# Install Docker Compose
sudo rm -f /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version
if [ $? -ne 0 ]; then
  echo "Docker Compose installation failed. Exiting."
  exit 1
fi

# Ensure Docker starts on boot and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Clone or update the repo
if [ -d "$APP_DIR" ]; then
  echo "Directory $APP_DIR exists. Pulling latest changes..."
  cd $APP_DIR && git pull
else
  echo "Cloning repo..."
  git clone $REPO_URL $APP_DIR
  cd $APP_DIR
fi

# Generate a self-signed SSL certificate
echo "Generating self-signed SSL certificate..."
sudo mkdir -p $SSL_DIR
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $SSL_DIR/selfsigned.key \
  -out $SSL_DIR/selfsigned.crt \
  -subj "/C=US/ST=VPS/L=Anywhere/O=SelfSigned/CN=$(hostname -I | awk '{print $1}')"

# Copy certs into app directory for Docker to use
sudo mkdir -p $APP_DIR/certs
sudo cp $SSL_DIR/selfsigned.* $APP_DIR/certs

# Create Dockerfile
cat > $APP_DIR/Dockerfile <<'EOF'
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 443
EOF

# Create Nginx config
cat > $APP_DIR/nginx.conf <<'EOF'
worker_processes 1;
events { worker_connections 1024; }
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;

    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate     /etc/ssl/myapp/selfsigned.crt;
        ssl_certificate_key /etc/ssl/myapp/selfsigned.key;

        location / {
            root   /usr/share/nginx/html;
            index  index.html;
        }
    }
}
EOF

# Create Docker Compose file
cat > $APP_DIR/docker-compose.yml <<'EOF'
version: '3.8'
services:
  web:
    build: .
    ports:
      - "443:443"
    volumes:
      - ./certs:/etc/ssl/myapp:ro
EOF

# Build and run containers
cd $APP_DIR
sudo docker-compose up --build -d

# Final check
if ! sudo docker-compose ps | grep "Up"; then
  echo "Docker containers failed to start. Check logs with 'docker-compose logs'."
  exit 1
fi

# Output access info
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Deployment complete!"
echo "Visit your site at: https://$IP_ADDRESS"
echo "Note: Browser will warn about self-signed certificate."
