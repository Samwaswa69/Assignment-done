FROM nginx:alpine

# Install git
RUN apk add --no-cache git

# Clone the GitHub repo into the web root
RUN git clone https://github.com/Samwaswa69/Assignment-done.git /usr/share/nginx/html

# Clean up .git directory (optional)
RUN rm -rf /usr/share/nginx/html/.git

# Expose port 80 and start Nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
