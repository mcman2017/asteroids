# Asteroids Frontend - Nginx Container
# Serves static game files with optimized configuration

FROM nginx:1.25-alpine

# Create non-root user for security
RUN addgroup -g 1001 -S asteroids && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G asteroids -g asteroids asteroids

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy game files
COPY --chown=asteroids:asteroids asteroids.html /usr/share/nginx/html/index.html
COPY --chown=asteroids:asteroids asteroids.js /usr/share/nginx/html/asteroids.js
COPY --chown=asteroids:asteroids styles.css /usr/share/nginx/html/styles.css

# Create necessary directories and set permissions
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    chown -R asteroids:asteroids /var/cache/nginx /var/log/nginx /var/run /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Switch to non-root user
USER asteroids

# Expose port 8080 (non-privileged)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
