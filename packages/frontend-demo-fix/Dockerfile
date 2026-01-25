FROM nginx:stable-alpine

RUN addgroup -S nginxgroup \
    && adduser -S nginxuser -G nginxgroup \
    && chown -R nginxuser:nginxgroup /usr/share/nginx/html \
    && chown -R nginxuser:nginxgroup /var/cache/nginx \
    && mkdir -p /run \
    && chown -R nginxuser:nginxgroup /run

# Add healthcheck to ensure nginx is running and responding
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# --- NEW: Copy template for runtime config ---
COPY config.js.template /etc/nginx/templates/config.js.template
ENV NGINX_ENVSUBST_OUTPUT_DIR=/usr/share/nginx/html
# ---------------------------------------------

# Copy dist and nginx configurations to the container
COPY --chown=nginxuser:nginxgroup dist/ /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose ports
EXPOSE 8080

# Set the user to run nginx
# This is to avoid running as root, which is a security best practice
USER nginxuser

# Set the default command to run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
