FROM nginx:alpine

# Install git
RUN apk add --no-cache git

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Clone the repo AFTER deletion
RUN git clone https://github.com/Samwaswa69/Assignment-done.git /usr/share/nginx/html

# Optional: Use your custom nginx.conf
# COPY /usr/share/nginx/html/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
