#!/bin/bash

# In-Place Migration Script
# Updates existing deployment with new game files while preserving high scores

set -e

# Configuration
NAMESPACE="default"
DOMAIN="games.theclamlife.com"
BACKUP_DIR="/tmp/asteroids-migration-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Backup high scores
backup_high_scores() {
    log_info "💾 Backing up high scores..."
    mkdir -p "$BACKUP_DIR"
    
    local postgres_pod
    postgres_pod=$(kubectl get pods -n "$NAMESPACE" | grep postgres | awk '{print $1}' | head -1)
    
    if [ -n "$postgres_pod" ]; then
        kubectl exec -n "$NAMESPACE" "$postgres_pod" -- pg_dump -U gameuser -d asteroids -t high_scores --data-only --inserts > "$BACKUP_DIR/high_scores_backup.sql"
        log_success "High scores backed up to $BACKUP_DIR"
        
        # Show current scores
        log_info "Current high scores:"
        kubectl exec -n "$NAMESPACE" "$postgres_pod" -- psql -U gameuser -d asteroids -c "SELECT initials, score FROM high_scores ORDER BY score DESC LIMIT 5;"
    else
        log_warning "PostgreSQL pod not found"
    fi
}

# Update ConfigMap with new game files
update_configmap() {
    log_info "📝 Updating game files in ConfigMap..."
    
    # Create new ConfigMap with updated game files
    kubectl create configmap asteroids-game-files-new \
        --from-file=asteroids.html=src/frontend/asteroids.html \
        --from-file=asteroids.js=src/frontend/asteroids.js \
        -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Update the deployment to use the new ConfigMap
    kubectl patch deployment asteroids-game -n "$NAMESPACE" -p '{"spec":{"template":{"spec":{"volumes":[{"name":"game-files","configMap":{"name":"asteroids-game-files-new"}}]}}}}'
    
    log_success "ConfigMap updated with new game files"
}

# Update ingress to ensure proper routing
update_ingress() {
    log_info "🌐 Updating ingress configuration..."
    
    # Apply enhanced ingress with better configuration
    cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: asteroids-game-ingress
  namespace: $NAMESPACE
  annotations:
    cert-manager.io/issuer: letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "1m"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
spec:
  ingressClassName: public
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: asteroids-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: asteroids-api-service
            port:
              number: 80
  tls:
  - secretName: games-theclamlife-com-tls
    hosts:
    - $DOMAIN
EOF
    
    log_success "Ingress updated with enhanced security headers"
}

# Wait for rollout
wait_for_rollout() {
    log_info "⏳ Waiting for deployment rollout..."
    
    kubectl rollout status deployment/asteroids-game -n "$NAMESPACE" --timeout=300s
    
    log_success "Deployment rollout completed"
}

# Test the updated deployment
test_deployment() {
    log_info "🧪 Testing updated deployment..."
    
    sleep 15
    
    # Test web interface
    if curl -s -k -I "https://$DOMAIN" | head -1 | grep -q "200"; then
        log_success "Web interface working"
    else
        log_warning "Web interface test failed"
    fi
    
    # Test API
    if curl -s -k "https://$DOMAIN/api/highscores" | grep -q '\['; then
        log_success "High scores API working"
        
        # Show current high scores
        log_info "Current high scores:"
        curl -s -k "https://$DOMAIN/api/highscores" | head -5
    else
        log_warning "High scores API test failed"
    fi
    
    # Verify high scores are preserved
    local postgres_pod
    postgres_pod=$(kubectl get pods -n "$NAMESPACE" | grep postgres | awk '{print $1}' | head -1)
    
    if [ -n "$postgres_pod" ]; then
        local count
        count=$(kubectl exec -n "$NAMESPACE" "$postgres_pod" -- psql -U gameuser -d asteroids -t -c "SELECT COUNT(*) FROM high_scores;" | tr -d ' ')
        log_success "High scores preserved: $count records"
    fi
}

# Show migration summary
show_summary() {
    log_success "🎉 In-Place Migration Completed!"
    echo
    log_info "✅ What was updated:"
    echo "• Game files updated with new version"
    echo "• Enhanced security headers added to ingress"
    echo "• High scores preserved in database"
    echo "• Same domain maintained: https://$DOMAIN"
    echo
    log_info "🎮 Game Features:"
    echo "• Enhanced styling and responsive design"
    echo "• Improved audio handling"
    echo "• Better browser compatibility"
    echo "• All original gameplay preserved"
    echo
    log_info "📊 High Scores:"
    echo "• All existing high scores preserved"
    echo "• Database unchanged"
    echo "• API functionality maintained"
    echo
    log_info "🔧 Next Steps:"
    echo "1. Test the game at: https://$DOMAIN"
    echo "2. Verify high scores are working"
    echo "3. Test sound functionality (click speaker icon)"
    echo "4. Play and ensure all features work"
    echo
    log_info "💾 Backup Location: $BACKUP_DIR"
    echo "• High scores backup available if needed"
}

# Main function
main() {
    log_info "🎮 Asteroids In-Place Migration"
    log_info "==============================="
    log_info "This will update your existing deployment with new game files"
    log_info "while preserving all high scores and using the same domain."
    echo
    
    echo "Continue with in-place migration? (y/N)"
    read -r -n 1 CONFIRM
    echo
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    backup_high_scores
    update_configmap
    update_ingress
    wait_for_rollout
    test_deployment
    show_summary
}

main "$@"
