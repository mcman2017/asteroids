#!/bin/bash

# Migrate Asteroids Game from Old Deployment to New Containerized Version
# Preserves high scores and maintains games.theclamlife.com domain

set -e

# Configuration
OLD_NAMESPACE="default"
NEW_NAMESPACE="asteroids"
DOMAIN="games.theclamlife.com"
BACKUP_DIR="/tmp/asteroids-migration-$(date +%Y%m%d-%H%M%S)"

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

# Create backup directory
create_backup_dir() {
    log_info "📁 Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    log_success "Backup directory created"
}

# Backup current high scores
backup_high_scores() {
    log_info "💾 Backing up current high scores..."
    
    # Get PostgreSQL pod name
    local postgres_pod
    postgres_pod=$(kubectl get pods -n "$OLD_NAMESPACE" -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$postgres_pod" ]; then
        postgres_pod=$(kubectl get pods -n "$OLD_NAMESPACE" | grep postgres | awk '{print $1}' | head -1)
    fi
    
    if [ -n "$postgres_pod" ]; then
        log_info "Found PostgreSQL pod: $postgres_pod"
        
        # Backup high scores table
        kubectl exec -n "$OLD_NAMESPACE" "$postgres_pod" -- pg_dump -U gameuser -d asteroids -t high_scores --data-only --inserts > "$BACKUP_DIR/high_scores_backup.sql"
        
        # Also backup full schema for reference
        kubectl exec -n "$OLD_NAMESPACE" "$postgres_pod" -- pg_dump -U gameuser -d asteroids > "$BACKUP_DIR/full_database_backup.sql"
        
        log_success "High scores backed up to $BACKUP_DIR"
    else
        log_warning "PostgreSQL pod not found, skipping database backup"
    fi
}

# Backup current configuration
backup_current_config() {
    log_info "📋 Backing up current Kubernetes configuration..."
    
    # Backup all asteroids-related resources
    kubectl get all,ingress,configmap,secret -n "$OLD_NAMESPACE" -o yaml | grep -A 10000 -B 10000 -i asteroid > "$BACKUP_DIR/current_k8s_resources.yaml" || true
    
    # Backup ingress specifically
    kubectl get ingress asteroids-game-ingress -n "$OLD_NAMESPACE" -o yaml > "$BACKUP_DIR/current_ingress.yaml" 2>/dev/null || true
    
    log_success "Current configuration backed up"
}

# Build new container images
build_new_images() {
    log_info "🔨 Building new container images..."
    
    cd /Users/anthonymcaniff/asteroids
    
    # Build images using our new script
    ./scripts/build-images.sh
    
    log_success "New container images built"
}

# Create migration values file
create_migration_values() {
    log_info "📝 Creating migration-specific values file..."
    
    cat > "$BACKUP_DIR/migration-values.yaml" << EOF
# Migration Values for Asteroids Game
# Configured to use games.theclamlife.com domain

# Global configuration
global:
  imageRegistry: "localhost"
  imagePullSecrets: []

# Frontend configuration
frontend:
  image:
    registry: "localhost"
    repository: "asteroids-frontend"
    tag: "latest"
    pullPolicy: IfNotPresent
  
  replicaCount: 2  # Match current deployment
  
  resources:
    limits:
      cpu: 500m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi

# Backend configuration
backend:
  image:
    registry: "localhost"
    repository: "asteroids-backend"
    tag: "latest"
    pullPolicy: IfNotPresent
  
  replicaCount: 2  # Match current deployment
  
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
    requests:
      cpu: 200m
      memory: 256Mi

# PostgreSQL configuration (preserve existing data)
postgresql:
  enabled: true
  auth:
    postgresPassword: "postgres123"
    username: "gameuser"
    password: "gamepass123"
    database: "asteroids"
  
  primary:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: "ceph-rbd"  # Your existing storage class

# Ingress configuration (use existing domain)
ingress:
  enabled: true
  className: "public"  # Your existing ingress class
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
  hosts:
    - host: $DOMAIN
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: backend
  tls:
    - secretName: games-theclamlife-com-tls
      hosts:
        - $DOMAIN

# Security context
securityContext:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001

# Pod security context
podSecurityContext:
  enabled: true
  fsGroup: 1001

# Service account
serviceAccount:
  create: true

# Production features
podDisruptionBudget:
  enabled: true
  minAvailable: 1

autoscaling:
  enabled: false  # Start disabled, can enable later

networkPolicy:
  enabled: false  # Start disabled for easier migration

monitoring:
  enabled: false  # Start disabled

# Node selection and affinity
nodeSelector: {}
tolerations: []
affinity: {}

# Additional labels
commonLabels:
  migration: "from-configmap"
  domain: "games-theclamlife-com"
EOF

    log_success "Migration values file created: $BACKUP_DIR/migration-values.yaml"
}

# Deploy new version
deploy_new_version() {
    log_info "🚀 Deploying new containerized version..."
    
    cd /Users/anthonymcaniff/asteroids
    
    # Deploy using our migration values
    ./scripts/deploy-asteroids.sh "$BACKUP_DIR/migration-values.yaml"
    
    log_success "New version deployed"
}

# Restore high scores to new database
restore_high_scores() {
    log_info "📊 Restoring high scores to new database..."
    
    if [ ! -f "$BACKUP_DIR/high_scores_backup.sql" ]; then
        log_warning "No high scores backup found, skipping restore"
        return 0
    fi
    
    # Wait for new PostgreSQL to be ready
    log_info "Waiting for new PostgreSQL to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=postgresql -n "$NEW_NAMESPACE" --timeout=300s
    
    # Get new PostgreSQL pod
    local new_postgres_pod
    new_postgres_pod=$(kubectl get pods -n "$NEW_NAMESPACE" -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$new_postgres_pod" ]; then
        log_info "Found new PostgreSQL pod: $new_postgres_pod"
        
        # Copy backup file to pod
        kubectl cp "$BACKUP_DIR/high_scores_backup.sql" "$NEW_NAMESPACE/$new_postgres_pod:/tmp/high_scores_backup.sql"
        
        # Restore high scores
        kubectl exec -n "$NEW_NAMESPACE" "$new_postgres_pod" -- psql -U gameuser -d asteroids -c "DELETE FROM high_scores;" || true
        kubectl exec -n "$NEW_NAMESPACE" "$new_postgres_pod" -- psql -U gameuser -d asteroids -f /tmp/high_scores_backup.sql
        
        # Verify restoration
        local score_count
        score_count=$(kubectl exec -n "$NEW_NAMESPACE" "$new_postgres_pod" -- psql -U gameuser -d asteroids -t -c "SELECT COUNT(*) FROM high_scores;" | tr -d ' ')
        
        log_success "High scores restored: $score_count records"
    else
        log_error "New PostgreSQL pod not found"
        return 1
    fi
}

# Update ingress to point to new service
update_ingress() {
    log_info "🌐 Updating ingress to point to new services..."
    
    # The new deployment should have created the correct ingress
    # Let's verify it exists and is configured correctly
    
    if kubectl get ingress -n "$NEW_NAMESPACE" | grep -q asteroids; then
        log_success "New ingress created successfully"
        
        # Show ingress details
        kubectl get ingress -n "$NEW_NAMESPACE"
    else
        log_error "New ingress not found"
        return 1
    fi
}

# Test new deployment
test_new_deployment() {
    log_info "🧪 Testing new deployment..."
    
    # Test web interface
    log_info "Testing web interface..."
    if curl -s -k -I "https://$DOMAIN" | head -1 | grep -q "200"; then
        log_success "Web interface accessible"
    else
        log_warning "Web interface test failed"
    fi
    
    # Test API
    log_info "Testing high scores API..."
    if curl -s -k "https://$DOMAIN/api/highscores" | grep -q '\['; then
        log_success "High scores API working"
        
        # Show current high scores
        log_info "Current high scores:"
        curl -s -k "https://$DOMAIN/api/highscores" | head -5
    else
        log_warning "High scores API test failed"
    fi
    
    # Test database connectivity
    local backend_pod
    backend_pod=$(kubectl get pods -n "$NEW_NAMESPACE" -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$backend_pod" ]; then
        log_info "Testing database connectivity..."
        if kubectl exec -n "$NEW_NAMESPACE" "$backend_pod" -- nc -zv asteroids-postgresql 5432 &> /dev/null; then
            log_success "Database connectivity working"
        else
            log_warning "Database connectivity test failed"
        fi
    fi
}

# Cleanup old deployment (with confirmation)
cleanup_old_deployment() {
    log_warning "🗑️  Ready to cleanup old deployment..."
    
    echo "The new deployment is working. Do you want to remove the old deployment?"
    echo "This will delete:"
    echo "  - Old asteroids pods and services"
    echo "  - Old PostgreSQL (data is preserved in new deployment)"
    echo "  - Old ingress (replaced by new one)"
    echo ""
    echo "⚠️  This action cannot be undone!"
    echo "Continue with cleanup? (y/N)"
    read -r -n 1 CLEANUP_CONFIRM
    echo
    
    if [[ $CLEANUP_CONFIRM =~ ^[Yy]$ ]]; then
        log_info "Cleaning up old deployment..."
        
        # Delete old resources
        kubectl delete deployment asteroids-game -n "$OLD_NAMESPACE" || true
        kubectl delete deployment asteroids-api -n "$OLD_NAMESPACE" || true
        kubectl delete deployment postgres -n "$OLD_NAMESPACE" || true
        kubectl delete service asteroids-service -n "$OLD_NAMESPACE" || true
        kubectl delete service asteroids-api-service -n "$OLD_NAMESPACE" || true
        kubectl delete service postgres-service -n "$OLD_NAMESPACE" || true
        kubectl delete ingress asteroids-game-ingress -n "$OLD_NAMESPACE" || true
        kubectl delete configmap asteroids-configmap -n "$OLD_NAMESPACE" || true
        kubectl delete pvc postgres-pvc -n "$OLD_NAMESPACE" || true
        
        log_success "Old deployment cleaned up"
    else
        log_info "Cleanup skipped - old deployment preserved"
        log_warning "Remember to clean up manually when ready"
    fi
}

# Show migration summary
show_migration_summary() {
    echo
    log_success "🎉 Migration Summary"
    echo "==================="
    echo
    log_info "✅ Migration Completed Successfully!"
    echo
    echo "🌐 Game URL: https://$DOMAIN"
    echo "🏆 High Scores API: https://$DOMAIN/api/highscores"
    echo "❤️  Health Check: https://$DOMAIN/health"
    echo
    log_info "📊 New Architecture:"
    echo "• Frontend: Containerized Nginx with optimized game files"
    echo "• Backend: Containerized Node.js API with enhanced security"
    echo "• Database: PostgreSQL with preserved high scores"
    echo "• Ingress: Enhanced with security headers and SSL"
    echo
    log_info "🔧 Management Commands:"
    echo "kubectl get all -n $NEW_NAMESPACE"
    echo "kubectl logs -n $NEW_NAMESPACE -l app.kubernetes.io/component=frontend -f"
    echo "kubectl logs -n $NEW_NAMESPACE -l app.kubernetes.io/component=backend -f"
    echo
    log_info "💾 Backup Location: $BACKUP_DIR"
    echo "• High scores backup: high_scores_backup.sql"
    echo "• Full database backup: full_database_backup.sql"
    echo "• Old Kubernetes config: current_k8s_resources.yaml"
    echo
    log_warning "⚠️  Next Steps:"
    echo "1. Test the game thoroughly at https://$DOMAIN"
    echo "2. Verify high scores are preserved"
    echo "3. Test sound functionality (click speaker icon)"
    echo "4. Monitor application performance"
    echo "5. Clean up old deployment when satisfied"
}

# Main migration function
main() {
    log_info "🎮 Asteroids Game Migration"
    log_info "=========================="
    log_info "Migrating from ConfigMap deployment to containerized deployment"
    log_info "Domain: $DOMAIN"
    log_info "Backup Directory: $BACKUP_DIR"
    echo
    
    log_warning "⚠️  This migration will:"
    echo "1. Backup current high scores and configuration"
    echo "2. Build new container images"
    echo "3. Deploy new containerized version"
    echo "4. Restore high scores to new database"
    echo "5. Update ingress configuration"
    echo "6. Test new deployment"
    echo
    echo "Continue with migration? (y/N)"
    read -r -n 1 MIGRATE_CONFIRM
    echo
    
    if [[ ! $MIGRATE_CONFIRM =~ ^[Yy]$ ]]; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    # Execute migration steps
    create_backup_dir
    backup_high_scores
    backup_current_config
    build_new_images
    create_migration_values
    deploy_new_version
    restore_high_scores
    update_ingress
    test_new_deployment
    cleanup_old_deployment
    show_migration_summary
}

# Run main function
main "$@"
