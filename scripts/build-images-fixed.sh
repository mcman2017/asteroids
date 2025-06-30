#!/bin/bash

# Build Container Images for Asteroids Game (Fixed Version)
# Uses Podman for secure, rootless container building

set -e

# Configuration
REGISTRY="localhost"
PROJECT="asteroids"
TAG="latest"
BUILD_FRONTEND=true
BUILD_BACKEND=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Build frontend image
build_frontend() {
    log_info "🔨 Building frontend image..."
    
    # Create temporary build directory
    local build_dir="/tmp/asteroids-frontend-build"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy files to build directory
    cp docker/frontend/Dockerfile "$build_dir/"
    cp docker/frontend/nginx.conf "$build_dir/"
    cp src/frontend/asteroids.html "$build_dir/"
    cp src/frontend/asteroids.js "$build_dir/"
    cp docker/frontend/styles.css "$build_dir/"
    
    # Build image
    podman build -t "$REGISTRY/$PROJECT-frontend:$TAG" -f "$build_dir/Dockerfile" "$build_dir"
    
    # Clean up
    rm -rf "$build_dir"
    
    log_success "Frontend image built: $REGISTRY/$PROJECT-frontend:$TAG"
}

# Build backend image
build_backend() {
    log_info "🔨 Building backend image..."
    
    # Create temporary build directory
    local build_dir="/tmp/asteroids-backend-build"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy files to build directory
    cp docker/backend/Dockerfile "$build_dir/"
    cp src/backend/package.json "$build_dir/"
    cp src/backend/api-server.js "$build_dir/"
    cp -r src/backend/database "$build_dir/" 2>/dev/null || true
    
    # Build image
    podman build -t "$REGISTRY/$PROJECT-backend:$TAG" -f "$build_dir/Dockerfile" "$build_dir"
    
    # Clean up
    rm -rf "$build_dir"
    
    log_success "Backend image built: $REGISTRY/$PROJECT-backend:$TAG"
}

# Main function
main() {
    log_info "🔨 Building Asteroids Game Container Images"
    
    if [ "$BUILD_FRONTEND" = true ]; then
        build_frontend
    fi
    
    if [ "$BUILD_BACKEND" = true ]; then
        build_backend
    fi
    
    log_success "🎉 All images built successfully!"
    
    # Show built images
    log_info "📋 Built images:"
    podman images | grep asteroids
}

# Run main function
main "$@"
