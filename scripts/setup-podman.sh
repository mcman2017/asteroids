#!/bin/bash

# Setup Podman for Asteroids Game Container Building
# Installs and configures Podman for secure container operations

set -e

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
Setup Podman for Asteroids Game Container Building

This script installs and configures Podman for building container images
for the Asteroids game deployment.

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    --test-only         Only test existing Podman installation
    --force-install     Force reinstallation even if Podman exists

EXAMPLES:
    $0                  # Install and test Podman
    $0 --test-only      # Test existing installation
    $0 --force-install  # Force reinstall Podman

EOF
}

# Parse command line arguments
TEST_ONLY=false
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --force-install)
            FORCE_INSTALL=true
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

# Check if Podman is already working
check_existing_podman() {
    log_info "🔍 Checking existing Podman installation..."
    
    if command -v podman &> /dev/null; then
        log_success "Podman command found: $(podman --version)"
        
        # Test basic functionality
        if podman run --rm hello-world &>/dev/null; then
            log_success "Podman is working correctly"
            return 0
        else
            log_warning "Podman installed but not working properly"
            return 1
        fi
    else
        log_info "Podman not found"
        return 1
    fi
}

# Install Podman based on OS
install_podman() {
    log_info "📦 Installing Podman..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_podman_macos
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        install_podman_linux
    else
        log_error "Unsupported operating system: $OSTYPE"
        log_info "Please install Podman manually for your system"
        exit 1
    fi
}

# Install Podman on macOS
install_podman_macos() {
    log_info "🍎 Installing Podman on macOS..."
    
    # Check if Homebrew is available
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew not found"
        log_info "Please install Homebrew first:"
        log_info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    log_info "🍺 Installing Podman via Homebrew..."
    brew install podman
    
    if [ $? -eq 0 ]; then
        log_success "Podman installed successfully"
    else
        log_error "Failed to install Podman via Homebrew"
        exit 1
    fi
    
    # Initialize Podman machine
    log_info "🔧 Initializing Podman machine..."
    if ! podman machine list | grep -q "Currently running"; then
        log_info "Creating and starting Podman machine..."
        podman machine init --cpus 2 --memory 4096 --disk-size 20
        podman machine start
    else
        log_success "Podman machine already running"
    fi
}

# Install Podman on Linux
install_podman_linux() {
    log_info "🐧 Installing Podman on Linux..."
    
    # Try different package managers
    if command -v apt-get &> /dev/null; then
        log_info "📦 Installing via apt..."
        sudo apt-get update
        sudo apt-get install -y podman
    elif command -v dnf &> /dev/null; then
        log_info "📦 Installing via dnf..."
        sudo dnf install -y podman
    elif command -v yum &> /dev/null; then
        log_info "📦 Installing via yum..."
        sudo yum install -y podman
    elif command -v pacman &> /dev/null; then
        log_info "📦 Installing via pacman..."
        sudo pacman -S podman
    else
        log_error "No supported package manager found"
        log_info "Please install Podman manually for your distribution"
        exit 1
    fi
}

# Test Podman functionality
test_podman() {
    log_info "🧪 Testing Podman functionality..."
    
    # Basic test
    log_info "Testing basic container functionality..."
    if podman run --rm hello-world; then
        log_success "Basic Podman test passed"
    else
        log_error "Basic Podman test failed"
        return 1
    fi
    
    # Test with Alpine (similar to our containers)
    log_info "Testing Alpine Linux container..."
    if podman run --rm alpine:latest echo "Alpine test successful"; then
        log_success "Alpine container test passed"
    else
        log_warning "Alpine container test failed"
    fi
    
    # Test with Node.js (for backend)
    log_info "Testing Node.js container..."
    if podman run --rm node:18-alpine node --version; then
        log_success "Node.js container test passed"
    else
        log_warning "Node.js container test failed"
    fi
    
    # Test with Nginx (for frontend)
    log_info "Testing Nginx container..."
    if podman run --rm nginx:alpine nginx -v; then
        log_success "Nginx container test passed"
    else
        log_warning "Nginx container test failed"
    fi
    
    return 0
}

# Test container building
test_container_building() {
    log_info "🔨 Testing container building capabilities..."
    
    # Create a simple test Dockerfile
    local test_dir="/tmp/podman-test-$$"
    mkdir -p "$test_dir"
    
    cat > "$test_dir/Dockerfile" << 'EOF'
FROM alpine:latest
RUN echo "Test container build" > /test.txt
CMD ["cat", "/test.txt"]
EOF
    
    # Test build
    if podman build -t test-build "$test_dir"; then
        log_success "Container build test passed"
        
        # Test run
        if podman run --rm test-build | grep -q "Test container build"; then
            log_success "Container run test passed"
        else
            log_warning "Container run test failed"
        fi
        
        # Clean up
        podman rmi test-build &> /dev/null || true
    else
        log_error "Container build test failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    # Clean up
    rm -rf "$test_dir"
    return 0
}

# Show usage information
show_usage_info() {
    log_success "🎉 Podman setup completed!"
    echo
    log_info "📋 Podman Commands for Reference:"
    echo "=================================="
    echo "podman --version              # Check version"
    echo "podman run --rm hello-world   # Test basic functionality"
    echo "podman machine list           # List machines (macOS)"
    echo "podman machine start          # Start machine (macOS)"
    echo "podman machine stop           # Stop machine (macOS)"
    echo "podman images                 # List local images"
    echo "podman ps                     # List running containers"
    echo
    
    log_info "🎮 Asteroids Game Container Building:"
    echo "===================================="
    echo "./scripts/build-images.sh             # Build all images"
    echo "./scripts/build-images.sh --frontend-only  # Build frontend only"
    echo "./scripts/build-images.sh --backend-only   # Build backend only"
    echo "./scripts/build-images.sh --test          # Test build process"
    echo
    
    log_info "🔧 Troubleshooting:"
    echo "==================="
    echo "If Podman doesn't work:"
    echo "1. On macOS: podman machine start"
    echo "2. Check permissions: podman system info"
    echo "3. Restart terminal/shell"
    echo "4. Try: podman run --rm hello-world"
    echo
    
    log_info "📚 Additional Resources:"
    echo "========================"
    echo "Podman Documentation: https://podman.io/docs"
    echo "Container Best Practices: https://developers.redhat.com/blog/2019/04/25/podman-basics-cheat-sheet"
}

# Main function
main() {
    log_info "🔧 Podman Setup for Asteroids Game"
    log_info "=================================="
    
    # Check existing installation
    if check_existing_podman && [ "$FORCE_INSTALL" = false ]; then
        if [ "$TEST_ONLY" = true ]; then
            log_success "Podman is already working correctly"
            test_podman
            test_container_building
            exit 0
        fi
        
        log_success "Podman is already installed and working"
        log_info "Use --force-install to reinstall or --test-only to test"
        
        # Still run tests
        test_podman
        test_container_building
        show_usage_info
        exit 0
    fi
    
    # Exit if test-only and Podman not working
    if [ "$TEST_ONLY" = true ]; then
        log_error "Podman not working properly"
        exit 1
    fi
    
    # Install Podman
    install_podman
    
    # Verify installation
    log_info "🔍 Verifying Podman installation..."
    if command -v podman &> /dev/null; then
        log_success "Podman command available: $(podman --version)"
    else
        log_error "Podman installation failed"
        exit 1
    fi
    
    # Test functionality
    if test_podman && test_container_building; then
        log_success "Podman is working correctly and ready for container building"
    else
        log_warning "Podman installed but some tests failed"
        log_info "You may need to restart your terminal or check configuration"
    fi
    
    # Show usage information
    show_usage_info
}

# Run main function
main "$@"
