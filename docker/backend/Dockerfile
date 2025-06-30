# Asteroids Backend API - Node.js Container
# Secure Node.js container for high score API

FROM node:18-alpine

# Create app directory and user
RUN addgroup -g 1001 -S asteroids && \
    adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -G asteroids -g asteroids asteroids

WORKDIR /app

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Copy package files first for better caching
COPY --chown=asteroids:asteroids package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force && \
    rm -rf /tmp/*

# Copy application files
COPY --chown=asteroids:asteroids api-server.js ./
COPY --chown=asteroids:asteroids database/ ./database/

# Create necessary directories
RUN mkdir -p /app/logs && \
    chown -R asteroids:asteroids /app

# Switch to non-root user
USER asteroids

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "api-server.js"]
