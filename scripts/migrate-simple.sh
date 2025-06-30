#!/bin/bash

# Simple Migration Script for Asteroids Game
# Migrates from ConfigMap to containerized deployment

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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Backup high scores
backup_high_scores() {
    log_info "💾 Backing up high scores..."
    mkdir -p "$BACKUP_DIR"
    
    local postgres_pod
    postgres_pod=$(kubectl get pods -n "$OLD_NAMESPACE" | grep postgres | awk '{print $1}' | head -1)
    
    if [ -n "$postgres_pod" ]; then
        kubectl exec -n "$OLD_NAMESPACE" "$postgres_pod" -- pg_dump -U gameuser -d asteroids -t high_scores --data-only --inserts > "$BACKUP_DIR/high_scores_backup.sql"
        log_success "High scores backed up"
    else
        log_warning "PostgreSQL pod not found"
    fi
}

# Deploy new version
deploy_new_version() {
    log_info "🚀 Deploying new containerized version..."
    
    # Create namespace
    kubectl create namespace "$NEW_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create simple deployment manifests
    cat << EOF | kubectl apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asteroids-frontend
  namespace: $NEW_NAMESPACE
  labels:
    app: asteroids-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: asteroids-frontend
  template:
    metadata:
      labels:
        app: asteroids-frontend
    spec:
      containers:
      - name: frontend
        image: localhost/asteroids-frontend:latest
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 200m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: asteroids-frontend
  namespace: $NEW_NAMESPACE
spec:
  selector:
    app: asteroids-frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asteroids-backend
  namespace: $NEW_NAMESPACE
  labels:
    app: asteroids-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: asteroids-backend
  template:
    metadata:
      labels:
        app: asteroids-backend
    spec:
      containers:
      - name: backend
        image: localhost/asteroids-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: PGHOST
          value: "asteroids-postgresql"
        - name: PGPORT
          value: "5432"
        - name: PGDATABASE
          value: "asteroids"
        - name: PGUSER
          value: "gameuser"
        - name: PGPASSWORD
          value: "gamepass123"
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: asteroids-backend
  namespace: $NEW_NAMESPACE
spec:
  selector:
    app: asteroids-backend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asteroids-postgresql
  namespace: $NEW_NAMESPACE
  labels:
    app: asteroids-postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: asteroids-postgresql
  template:
    metadata:
      labels:
        app: asteroids-postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "asteroids"
        - name: POSTGRES_USER
          value: "gameuser"
        - name: POSTGRES_PASSWORD
          value: "gamepass123"
        - name: PGDATA
          value: "/var/lib/postgresql/data/pgdata"
        volumeMounts:
        - name: postgresql-data
          mountPath: /var/lib/postgresql/data
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
      volumes:
      - name: postgresql-data
        persistentVolumeClaim:
          claimName: asteroids-postgresql-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: asteroids-postgresql-pvc
  namespace: $NEW_NAMESPACE
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ceph-rbd
---
apiVersion: v1
kind: Service
metadata:
  name: asteroids-postgresql
  namespace: $NEW_NAMESPACE
spec:
  selector:
    app: asteroids-postgresql
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: asteroids-ingress
  namespace: $NEW_NAMESPACE
  annotations:
    cert-manager.io/issuer: letsencrypt
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
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
            name: asteroids-frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: asteroids-backend
            port:
              number: 3000
  tls:
  - secretName: games-theclamlife-com-tls
    hosts:
    - $DOMAIN
EOF

    log_success "New deployment created"
}

# Wait for deployment
wait_for_deployment() {
    log_info "⏳ Waiting for deployment to be ready..."
    
    kubectl rollout status deployment/asteroids-frontend -n "$NEW_NAMESPACE" --timeout=300s
    kubectl rollout status deployment/asteroids-backend -n "$NEW_NAMESPACE" --timeout=300s
    kubectl rollout status deployment/asteroids-postgresql -n "$NEW_NAMESPACE" --timeout=300s
    
    kubectl wait --for=condition=Ready pod -l app=asteroids-postgresql -n "$NEW_NAMESPACE" --timeout=300s
    
    log_success "Deployment is ready"
}

# Restore high scores
restore_high_scores() {
    log_info "📊 Restoring high scores..."
    
    if [ ! -f "$BACKUP_DIR/high_scores_backup.sql" ]; then
        log_warning "No backup found, skipping restore"
        return 0
    fi
    
    local postgres_pod
    postgres_pod=$(kubectl get pods -n "$NEW_NAMESPACE" -l app=asteroids-postgresql -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$postgres_pod" ]; then
        # Wait a bit more for PostgreSQL to be fully ready
        sleep 30
        
        # Initialize database schema first
        kubectl exec -n "$NEW_NAMESPACE" "$postgres_pod" -- psql -U gameuser -d asteroids -c "
        CREATE TABLE IF NOT EXISTS high_scores (
            id SERIAL PRIMARY KEY,
            initials VARCHAR(3) NOT NULL,
            score INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"
        
        # Copy and restore backup
        kubectl cp "$BACKUP_DIR/high_scores_backup.sql" "$NEW_NAMESPACE/$postgres_pod:/tmp/backup.sql"
        kubectl exec -n "$NEW_NAMESPACE" "$postgres_pod" -- psql -U gameuser -d asteroids -f /tmp/backup.sql
        
        # Verify
        local count
        count=$(kubectl exec -n "$NEW_NAMESPACE" "$postgres_pod" -- psql -U gameuser -d asteroids -t -c "SELECT COUNT(*) FROM high_scores;" | tr -d ' ')
        log_success "High scores restored: $count records"
    fi
}

# Test deployment
test_deployment() {
    log_info "🧪 Testing new deployment..."
    
    sleep 30
    
    if curl -s -k -I "https://$DOMAIN" | head -1 | grep -q "200"; then
        log_success "Web interface working"
    else
        log_warning "Web interface test failed"
    fi
    
    if curl -s -k "https://$DOMAIN/api/highscores" | grep -q '\['; then
        log_success "API working"
        log_info "High scores: $(curl -s -k "https://$DOMAIN/api/highscores" | head -3)"
    else
        log_warning "API test failed"
    fi
}

# Cleanup old deployment
cleanup_old() {
    log_warning "🗑️  Cleanup old deployment?"
    echo "Remove old asteroids deployment? (y/N)"
    read -r -n 1 CLEANUP
    echo
    
    if [[ $CLEANUP =~ ^[Yy]$ ]]; then
        kubectl delete deployment asteroids-game asteroids-api postgres -n "$OLD_NAMESPACE" || true
        kubectl delete service asteroids-service asteroids-api-service postgres-service -n "$OLD_NAMESPACE" || true
        kubectl delete ingress asteroids-game-ingress -n "$OLD_NAMESPACE" || true
        kubectl delete configmap asteroids-configmap -n "$OLD_NAMESPACE" || true
        log_success "Old deployment cleaned up"
    fi
}

# Main function
main() {
    log_info "🎮 Simple Asteroids Migration"
    log_info "============================="
    
    echo "Migrate asteroids game to containerized deployment? (y/N)"
    read -r -n 1 CONFIRM
    echo
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    backup_high_scores
    deploy_new_version
    wait_for_deployment
    restore_high_scores
    test_deployment
    cleanup_old
    
    log_success "🎉 Migration completed!"
    log_info "Game URL: https://$DOMAIN"
    log_info "Backup: $BACKUP_DIR"
}

main "$@"
