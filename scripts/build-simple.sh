#!/bin/bash

# Simple Container Build for Migration
# Quick build for migration purposes

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_info "🔨 Building simple containers for migration..."

# Build frontend with simple Dockerfile
log_info "Building frontend..."
cat > /tmp/frontend.dockerfile << 'EOF'
FROM nginx:alpine
COPY src/frontend/asteroids.html /usr/share/nginx/html/index.html
COPY src/frontend/asteroids.js /usr/share/nginx/html/asteroids.js
EXPOSE 80
EOF

podman build -t localhost/asteroids-frontend:latest -f /tmp/frontend.dockerfile .

# Build backend with simple Dockerfile
log_info "Building backend..."
cat > /tmp/backend.dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY src/backend/package.json ./
RUN npm install
COPY src/backend/api-server.js ./
EXPOSE 3000
CMD ["npm", "start"]
EOF

podman build -t localhost/asteroids-backend:latest -f /tmp/backend.dockerfile .

# Clean up
rm -f /tmp/frontend.dockerfile /tmp/backend.dockerfile

log_success "Simple containers built successfully!"
podman images | grep asteroids
