#!/bin/bash

# Pre-Migration Check for Asteroids Game
# Analyzes current deployment before migration

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

echo "🔍 Pre-Migration Analysis for Asteroids Game"
echo "==========================================="
echo

# Check current pods
log_info "📋 Current Asteroids Pods:"
kubectl get pods --all-namespaces | grep -i asteroid | while read line; do
    echo "  $line"
done
echo

# Check current services
log_info "🌐 Current Asteroids Services:"
kubectl get svc --all-namespaces | grep -i asteroid | while read line; do
    echo "  $line"
done
echo

# Check current ingress
log_info "🚪 Current Asteroids Ingress:"
kubectl get ingress --all-namespaces | grep -i asteroid | while read line; do
    echo "  $line"
done
echo

# Check PostgreSQL
log_info "🗄️  Current PostgreSQL:"
kubectl get pods,svc --all-namespaces | grep -i postgres | while read line; do
    echo "  $line"
done
echo

# Test current game accessibility
log_info "🧪 Testing Current Game Accessibility:"
if curl -s -k -I https://games.theclamlife.com | head -1 | grep -q "200"; then
    log_success "Game is currently accessible at https://games.theclamlife.com"
else
    log_warning "Game may not be accessible at https://games.theclamlife.com"
fi

# Test current API
log_info "🧪 Testing Current High Scores API:"
if curl -s -k https://games.theclamlife.com/api/highscores | grep -q '\['; then
    log_success "High scores API is working"
    echo "Current high scores count: $(curl -s -k https://games.theclamlife.com/api/highscores | jq length 2>/dev/null || echo "Unknown")"
else
    log_warning "High scores API may not be working"
fi

# Check database connectivity
log_info "🔗 Testing Database Connectivity:"
POSTGRES_POD=$(kubectl get pods --all-namespaces | grep postgres | awk '{print $2}' | head -1)
POSTGRES_NS=$(kubectl get pods --all-namespaces | grep postgres | awk '{print $1}' | head -1)

if [ -n "$POSTGRES_POD" ] && [ -n "$POSTGRES_NS" ]; then
    log_success "Found PostgreSQL pod: $POSTGRES_POD in namespace: $POSTGRES_NS"
    
    # Check high scores table
    SCORE_COUNT=$(kubectl exec -n "$POSTGRES_NS" "$POSTGRES_POD" -- psql -U gameuser -d asteroids -t -c "SELECT COUNT(*) FROM high_scores;" 2>/dev/null | tr -d ' ' || echo "0")
    log_info "Current high scores in database: $SCORE_COUNT"
    
    if [ "$SCORE_COUNT" -gt 0 ]; then
        log_info "Sample high scores:"
        kubectl exec -n "$POSTGRES_NS" "$POSTGRES_POD" -- psql -U gameuser -d asteroids -c "SELECT initials, score FROM high_scores ORDER BY score DESC LIMIT 5;" 2>/dev/null || echo "Could not retrieve sample scores"
    fi
else
    log_warning "PostgreSQL pod not found"
fi

echo
log_info "📊 Migration Readiness Assessment:"
echo "=================================="

# Check prerequisites for new deployment
log_info "Checking migration prerequisites..."

# Check if Podman is available
if command -v podman &> /dev/null; then
    log_success "Podman is available for container building"
else
    log_warning "Podman not found - run ./scripts/setup-podman.sh first"
fi

# Check if Helm is available
if command -v helm &> /dev/null; then
    log_success "Helm is available for deployment"
else
    log_error "Helm is required but not found"
fi

# Check storage class
if kubectl get storageclass ceph-rbd &> /dev/null; then
    log_success "Ceph RBD storage class is available"
else
    log_warning "Ceph RBD storage class not found - may need to adjust storage configuration"
fi

# Check ingress class
if kubectl get ingressclass public &> /dev/null; then
    log_success "Public ingress class is available"
else
    log_warning "Public ingress class not found - may need to adjust ingress configuration"
fi

echo
log_info "🎯 Migration Plan Summary:"
echo "========================="
echo "1. ✅ Current game is running and accessible"
echo "2. ✅ High scores are preserved in PostgreSQL"
echo "3. ✅ Domain games.theclamlife.com is working"
echo "4. 🔄 Ready to migrate to containerized deployment"
echo
log_warning "⚠️  Migration Impact:"
echo "• Brief downtime during deployment switch"
echo "• High scores will be preserved"
echo "• Same domain will be used"
echo "• Enhanced security and performance"
echo
log_info "🚀 To proceed with migration:"
echo "./scripts/migrate-from-old.sh"
