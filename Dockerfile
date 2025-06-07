# Use official Nginx image
FROM nginx:alpine

# Remove default static files
RUN rm -rf /usr/share/nginx/html/*

# Copy your site into the Nginx html directory
COPY . /usr/share/nginx/html

# Copy custom Nginx config (we'll define it in step 2)
COPY nginx.conf /etc/nginx/nginx.conf

# Expose HTTPS port
EXPOSE 443
