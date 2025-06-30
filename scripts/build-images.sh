#!/bin/bash

# Build Container Images for Asteroids Game
# Uses Podman for secure, rootless container building

set -e

# Configuration
REGISTRY="localhost"  # Change to your registry
PROJECT="asteroids"
TAG="latest"
BUILD_FRONTEND=true
BUILD_BACKEND=true
PUSH_IMAGES=false
TEST_BUILD=false

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

# Help function
show_help() {
    cat << EOF
Build Container Images for Asteroids Game

This script builds frontend and backend container images using Podman
for secure, rootless container operations.

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    --frontend-only         Build only frontend image
    --backend-only          Build only backend image
    --tag TAG              Use specific tag (default: latest)
    --registry REGISTRY    Use specific registry (default: localhost)
    --push                 Push images to registry after building
    --test                 Test build without creating final images
    --no-cache             Build without using cache

EXAMPLES:
    $0                              # Build both images
    $0 --frontend-only              # Build only frontend
    $0 --tag v1.0.0 --push          # Build and push with version tag
    $0 --test                       # Test build process

EOF
}

# Parse command line arguments
NO_CACHE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --frontend-only)
            BUILD_FRONTEND=true
            BUILD_BACKEND=false
            shift
            ;;
        --backend-only)
            BUILD_FRONTEND=false
            BUILD_BACKEND=true
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --test)
            TEST_BUILD=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown argument $1"
            show_help
            exit 1
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log_info "📋 Checking prerequisites..."
    
    # Check Podman
    if ! command -v podman &> /dev/null; then
        log_error "Podman is required but not installed"
        log_info "Install with: brew install podman (macOS)"
        exit 1
    fi
    
    # Check Podman machine (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! podman machine list | grep -q "Currently running"; then
            log_warning "Podman machine not running, attempting to start..."
            podman machine start || {
                log_error "Failed to start Podman machine"
                exit 1
            }
        fi
    fi
    
    # Test Podman functionality
    if ! podman --version &> /dev/null; then
        log_error "Podman not working properly"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    log_info "Podman version: $(podman --version)"
}

# Prepare build context
prepare_build_context() {
    local component="$1"
    local build_dir="/tmp/asteroids-build-$component-$$"
    
    log_info "📁 Preparing build context for $component..."
    
    # Create temporary build directory
    mkdir -p "$build_dir"
    
    if [ "$component" = "frontend" ]; then
        # Copy frontend files
        cp docker/frontend/Dockerfile "$build_dir/"
        cp docker/frontend/nginx.conf "$build_dir/"
        cp src/frontend/asteroids.html "$build_dir/"
        cp src/frontend/asteroids.js "$build_dir/"
        cp docker/frontend/styles.css "$build_dir/"
        
    elif [ "$component" = "backend" ]; then
        # Copy backend files
        cp docker/backend/Dockerfile "$build_dir/"
        cp src/backend/package.json "$build_dir/"
        cp src/backend/api-server.js "$build_dir/"
        cp -r src/backend/database "$build_dir/"
    fi
    
    echo "$build_dir"
}

# Build image
build_image() {
    local component="$1"
    local image_name="$REGISTRY/$PROJECT-$component:$TAG"
    
    log_info "🔨 Building $component image: $image_name"
    
    # Prepare build context
    local build_dir
    build_dir=$(prepare_build_context "$component")
    
    # Build arguments
    local build_args=(
        "build"
        "-t" "$image_name"
        "-f" "$build_dir/Dockerfile"
    )
    
    # Add no-cache if requested
    if [ "$NO_CACHE" = true ]; then
        build_args+=("--no-cache")
    fi
    
    # Add build context
    build_args+=("$build_dir")
    
    # Build image
    if [ "$TEST_BUILD" = true ]; then
        log_info "TEST BUILD: Would run: podman ${build_args[*]}"
    else
        podman "${build_args[@]}"
        log_success "$component image built successfully"
    fi
    
    # Clean up build context
    rm -rf "$build_dir"
    
    # Test image if not in test mode
    if [ "$TEST_BUILD" = false ]; then
        test_image "$component" "$image_name"
    fi
}

# Test image
test_image() {
    local component="$1"
    local image_name="$2"
    
    log_info "🧪 Testing $component image..."
    
    # Basic image inspection
    if ! podman inspect "$image_name" &> /dev/null; then
        log_error "Image inspection failed for $image_name"
        return 1
    fi
    
    # Test container startup
    local container_id
    if [ "$component" = "frontend" ]; then
        container_id=$(podman run -d --rm -p 0:8080 "$image_name")
        sleep 3
        
        # Test health endpoint
        local port
        port=$(podman port "$container_id" 8080 | cut -d: -f2)
        if curl -s "http://localhost:$port/health" | grep -q "healthy"; then
            log_success "Frontend container test passed"
        else
            log_warning "Frontend health check failed (may be normal)"
        fi
        
        podman stop "$container_id" &> /dev/null
        
    elif [ "$component" = "backend" ]; then
        # Backend needs database, so just test startup
        container_id=$(podman run -d --rm "$image_name" sh -c "sleep 5")
        sleep 2
        
        if podman ps | grep -q "$container_id"; then
            log_success "Backend container test passed"
        else
            log_warning "Backend container test failed"
        fi
        
        podman stop "$container_id" &> /dev/null
    fi
}

# Push image
push_image() {
    local component="$1"
    local image_name="$REGISTRY/$PROJECT-$component:$TAG"
    
    if [ "$PUSH_IMAGES" = true ] && [ "$TEST_BUILD" = false ]; then
        log_info "📤 Pushing $component image to registry..."
        
        if [ "$REGISTRY" = "localhost" ]; then
            log_warning "Skipping push for localhost registry"
            return 0
        fi
        
        podman push "$image_name"
        log_success "$component image pushed successfully"
    fi
}

# Show build summary
show_summary() {
    echo
    log_success "🎉 Build Summary"
    echo "================"
    
    if [ "$TEST_BUILD" = true ]; then
        echo "Mode: TEST BUILD (no images created)"
    else
        echo "Mode: PRODUCTION BUILD"
    fi
    
    echo "Registry: $REGISTRY"
    echo "Tag: $TAG"
    echo
    
    if [ "$BUILD_FRONTEND" = true ]; then
        local frontend_image="$REGISTRY/$PROJECT-frontend:$TAG"
        echo "Frontend Image: $frontend_image"
        if [ "$TEST_BUILD" = false ]; then
            echo "Size: $(podman images --format "{{.Size}}" "$frontend_image" 2>/dev/null || echo "Unknown")"
        fi
    fi
    
    if [ "$BUILD_BACKEND" = true ]; then
        local backend_image="$REGISTRY/$PROJECT-backend:$TAG"
        echo "Backend Image: $backend_image"
        if [ "$TEST_BUILD" = false ]; then
            echo "Size: $(podman images --format "{{.Size}}" "$backend_image" 2>/dev/null || echo "Unknown")"
        fi
    fi
    
    echo
    log_info "🚀 Next Steps:"
    echo "1. Test images locally: podman run --rm -p 8080:8080 $REGISTRY/$PROJECT-frontend:$TAG"
    echo "2. Deploy to Kubernetes: ./scripts/deploy-asteroids.sh"
    echo "3. Update image tags in values.yaml if using custom tag"
    
    if [ "$PUSH_IMAGES" = false ] && [ "$REGISTRY" != "localhost" ]; then
        echo "4. Push images: $0 --push --tag $TAG"
    fi
}

# Main function
main() {
    log_info "🔨 Asteroids Game - Container Image Builder"
    log_info "==========================================="
    
    # Check prerequisites
    check_prerequisites
    
    # Build frontend
    if [ "$BUILD_FRONTEND" = true ]; then
        build_image "frontend"
        push_image "frontend"
    fi
    
    # Build backend
    if [ "$BUILD_BACKEND" = true ]; then
        build_image "backend"
        push_image "backend"
    fi
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
