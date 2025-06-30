#!/bin/bash

# Asteroids Game Kubernetes Deployment Script
# Production-ready deployment with PostgreSQL backend

set -e

# Configuration
NAMESPACE="asteroids"
RELEASE_NAME="asteroids"
CHART_PATH="../helm-chart/asteroids"
DEFAULT_VALUES="examples/values-production.yaml"

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
Asteroids Game Kubernetes Deployment Script

Usage: $0 [OPTIONS] [VALUES_FILE]

OPTIONS:
    -h, --help          Show this help message
    -n, --namespace     Kubernetes namespace (default: asteroids)
    -r, --release       Helm release name (default: asteroids)
    --dry-run          Perform a dry run without actual deployment
    --upgrade          Upgrade existing deployment
    --uninstall        Uninstall existing deployment
    --build-images     Build container images before deployment

EXAMPLES:
    $0                                    # Deploy with default values
    $0 my-values.yaml                     # Deploy with custom values
    $0 --upgrade my-values.yaml           # Upgrade existing deployment
    $0 --build-images --upgrade           # Build images and upgrade
    $0 --dry-run                          # Test deployment without applying

EOF
}

# Parse command line arguments
DRY_RUN=false
UPGRADE=false
UNINSTALL=false
BUILD_IMAGES=false
VALUES_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --upgrade)
            UPGRADE=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --build-images)
            BUILD_IMAGES=true
            shift
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            VALUES_FILE="$1"
            shift
            ;;
    esac
done

# Set default values file if not specified
if [ -z "$VALUES_FILE" ]; then
    VALUES_FILE="$DEFAULT_VALUES"
fi

# Main deployment function
main() {
    log_info "🎮 Asteroids Game Kubernetes Deployment"
    log_info "======================================="
    
    # Handle uninstall
    if [ "$UNINSTALL" = true ]; then
        uninstall_asteroids
        exit 0
    fi
    
    # Build images if requested
    if [ "$BUILD_IMAGES" = true ]; then
        build_container_images
    fi
    
    # Pre-flight checks
    check_prerequisites
    
    # Create namespace
    create_namespace
    
    # Deploy or upgrade
    if [ "$UPGRADE" = true ]; then
        upgrade_asteroids
    else
        deploy_asteroids
    fi
    
    # Post-deployment verification
    if [ "$DRY_RUN" = false ]; then
        verify_deployment
        show_access_info
    fi
}

# Build container images
build_container_images() {
    log_info "🔨 Building container images..."
    
    if [ ! -f "scripts/build-images.sh" ]; then
        log_error "Build script not found. Run from project root directory."
        exit 1
    fi
    
    ./scripts/build-images.sh
    log_success "Container images built successfully"
}

# Check prerequisites
check_prerequisites() {
    log_info "📋 Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is required but not installed"
        exit 1
    fi
    
    # Check values file
    if [ ! -f "$VALUES_FILE" ]; then
        log_error "Values file not found: $VALUES_FILE"
        exit 1
    fi
    
    # Check chart directory
    if [ ! -d "$CHART_PATH" ]; then
        log_error "Helm chart not found: $CHART_PATH"
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "📁 Creating namespace: $NAMESPACE"
    
    if [ "$DRY_RUN" = false ]; then
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        log_success "Namespace ready: $NAMESPACE"
    else
        log_info "DRY RUN: Would create namespace $NAMESPACE"
    fi
}

# Deploy Asteroids
deploy_asteroids() {
    log_info "🚀 Deploying Asteroids Game..."
    log_info "Namespace: $NAMESPACE"
    log_info "Release: $RELEASE_NAME"
    log_info "Values: $VALUES_FILE"
    
    local helm_args=(
        "upgrade" "--install" "$RELEASE_NAME" "$CHART_PATH"
        "--namespace" "$NAMESPACE"
        "--values" "$VALUES_FILE"
        "--timeout" "10m"
        "--wait"
    )
    
    if [ "$DRY_RUN" = true ]; then
        helm_args+=("--dry-run")
        log_info "DRY RUN: Helm deployment simulation"
    fi
    
    helm "${helm_args[@]}"
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Asteroids Game deployed successfully"
    else
        log_success "DRY RUN: Deployment simulation completed"
    fi
}

# Upgrade Asteroids
upgrade_asteroids() {
    log_info "🔄 Upgrading Asteroids Game..."
    
    # Check if release exists
    if ! helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        log_warning "Release $RELEASE_NAME not found, performing fresh deployment"
        deploy_asteroids
        return
    fi
    
    local helm_args=(
        "upgrade" "$RELEASE_NAME" "$CHART_PATH"
        "--namespace" "$NAMESPACE"
        "--values" "$VALUES_FILE"
        "--timeout" "10m"
        "--wait"
    )
    
    if [ "$DRY_RUN" = true ]; then
        helm_args+=("--dry-run")
        log_info "DRY RUN: Helm upgrade simulation"
    fi
    
    helm "${helm_args[@]}"
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Asteroids Game upgraded successfully"
    else
        log_success "DRY RUN: Upgrade simulation completed"
    fi
}

# Uninstall Asteroids
uninstall_asteroids() {
    log_warning "🗑️  Uninstalling Asteroids Game..."
    
    echo "This will remove the Asteroids Game but preserve database data (PVC)."
    echo "Are you sure you want to continue? (y/N)"
    read -r -n 1 CONFIRM
    echo
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    # Uninstall Helm release
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
        log_success "Helm release uninstalled"
    else
        log_warning "Helm release not found"
    fi
    
    # Show remaining resources
    log_info "Remaining resources in namespace $NAMESPACE:"
    kubectl get all,pvc,secrets -n "$NAMESPACE" 2>/dev/null || true
    
    log_warning "PVC and secrets preserved. Delete manually if needed."
}

# Verify deployment
verify_deployment() {
    log_info "🔍 Verifying deployment..."
    
    # Wait for deployments
    log_info "Waiting for deployments to be ready..."
    kubectl rollout status deployment/"$RELEASE_NAME-frontend" -n "$NAMESPACE" --timeout=300s
    kubectl rollout status deployment/"$RELEASE_NAME-backend" -n "$NAMESPACE" --timeout=300s
    
    # Check if PostgreSQL is enabled and wait for it
    if kubectl get deployment "$RELEASE_NAME-postgresql" -n "$NAMESPACE" &> /dev/null; then
        kubectl rollout status deployment/"$RELEASE_NAME-postgresql" -n "$NAMESPACE" --timeout=300s
    fi
    
    # Wait for pod readiness
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance="$RELEASE_NAME" -n "$NAMESPACE" --timeout=300s
    
    # Check pod status
    log_info "Pod status:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    
    # Check services
    log_info "Services:"
    kubectl get svc -n "$NAMESPACE"
    
    # Check ingress
    log_info "Ingress:"
    kubectl get ingress -n "$NAMESPACE"
    
    # Check PVC
    log_info "Storage:"
    kubectl get pvc -n "$NAMESPACE"
    
    log_success "Deployment verification completed"
}

# Test application functionality
test_application() {
    log_info "🧪 Testing application functionality..."
    
    # Get ingress host
    local ingress_host
    ingress_host=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "localhost")
    
    # Test frontend
    if curl -s -k -I "https://$ingress_host" | head -1 | grep -q "200"; then
        log_success "Frontend accessible"
    else
        log_warning "Frontend may not be ready yet"
    fi
    
    # Test backend API
    if curl -s -k "https://$ingress_host/api/highscores" | grep -q '\['; then
        log_success "Backend API working"
    else
        log_warning "Backend API may not be ready yet"
    fi
    
    # Test database connectivity
    local backend_pod
    backend_pod=$(kubectl get pods -n "$NAMESPACE" -l app="$RELEASE_NAME-backend" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$backend_pod" ]; then
        if kubectl exec -n "$NAMESPACE" "$backend_pod" -- nc -zv postgresql 5432 &> /dev/null; then
            log_success "Database connectivity working"
        else
            log_warning "Database connectivity test failed"
        fi
    fi
}

# Show access information
show_access_info() {
    log_success "🎉 Asteroids Game deployment completed!"
    echo
    log_info "📋 Access Information:"
    echo "=================================="
    
    # Get ingress host
    local ingress_host
    ingress_host=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "asteroids.yourdomain.com")
    
    echo "🎮 Game URL: https://$ingress_host"
    echo "🏆 High Scores API: https://$ingress_host/api/highscores"
    echo "❤️  Health Check: https://$ingress_host/health"
    echo
    
    log_info "🎮 Game Features:"
    echo "• Classic Asteroids gameplay"
    echo "• Sound effects (click speaker icon to enable)"
    echo "• High score persistence"
    echo "• Responsive design"
    echo
    
    log_info "🕹️  Game Controls:"
    echo "• Arrow Keys: Move and rotate ship"
    echo "• Spacebar: Fire weapons"
    echo "• Up Arrow: Thrust forward"
    echo "• Down Arrow: Hyperspace jump"
    echo
    
    log_info "📊 Monitoring Commands:"
    echo "kubectl get pods -n $NAMESPACE -w"
    echo "kubectl logs -n $NAMESPACE -l app=$RELEASE_NAME-frontend -f"
    echo "kubectl logs -n $NAMESPACE -l app=$RELEASE_NAME-backend -f"
    echo
    
    log_info "🔧 Management Commands:"
    echo "./scripts/manage-database.sh status     # Check database status"
    echo "./scripts/manage-database.sh backup     # Backup high scores"
    echo "./scripts/build-images.sh --push        # Update container images"
    echo
    
    log_warning "⚠️  Next Steps:"
    echo "1. Test the game at: https://$ingress_host"
    echo "2. Click the sound toggle (🔇) to enable audio"
    echo "3. Play and submit high scores"
    echo "4. Monitor application health and performance"
    
    # Test application
    test_application
}

# Run main function
main "$@"
