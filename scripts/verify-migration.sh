#!/bin/bash

# Verify Migration Success
# Comprehensive testing of the migrated asteroids game

set -e

# Configuration
DOMAIN="games.theclamlife.com"

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

echo "🔍 Migration Verification for Asteroids Game"
echo "==========================================="
echo

# Test 1: Web Interface
log_info "🌐 Testing Web Interface..."
WEB_RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$DOMAIN")
if [ "$WEB_RESPONSE" = "200" ]; then
    log_success "Web interface accessible (HTTP $WEB_RESPONSE)"
else
    log_error "Web interface failed (HTTP $WEB_RESPONSE)"
fi

# Test 2: High Scores API
log_info "🏆 Testing High Scores API..."
API_RESPONSE=$(curl -s -k "https://$DOMAIN/api/highscores")
if echo "$API_RESPONSE" | grep -q '\['; then
    log_success "High scores API working"
    SCORE_COUNT=$(echo "$API_RESPONSE" | jq length 2>/dev/null || echo "Unknown")
    log_info "High scores count: $SCORE_COUNT"
    
    # Show top 3 scores
    log_info "Top scores:"
    echo "$API_RESPONSE" | jq -r '.[:3] | .[] | "  \(.initials): \(.score)"' 2>/dev/null || echo "  Could not parse scores"
else
    log_error "High scores API failed"
fi

# Test 3: Database Connectivity
log_info "🗄️  Testing Database Connectivity..."
POSTGRES_POD=$(kubectl get pods -n default | grep postgres | awk '{print $1}' | head -1)
if [ -n "$POSTGRES_POD" ]; then
    DB_COUNT=$(kubectl exec -n default "$POSTGRES_POD" -- psql -U gameuser -d asteroids -t -c "SELECT COUNT(*) FROM high_scores;" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$DB_COUNT" -gt 0 ]; then
        log_success "Database accessible with $DB_COUNT high scores"
    else
        log_warning "Database accessible but no scores found"
    fi
else
    log_error "PostgreSQL pod not found"
fi

# Test 4: Deployment Status
log_info "📋 Checking Deployment Status..."
FRONTEND_READY=$(kubectl get deployment asteroids-game -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
API_READY=$(kubectl get deployment asteroids-api -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
DB_READY=$(kubectl get deployment postgres -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

log_info "Pod status:"
echo "  Frontend pods ready: $FRONTEND_READY"
echo "  API pods ready: $API_READY"
echo "  Database pods ready: $DB_READY"

# Test 5: Ingress Configuration
log_info "🚪 Checking Ingress Configuration..."
INGRESS_HOST=$(kubectl get ingress asteroids-game-ingress -n default -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
if [ "$INGRESS_HOST" = "$DOMAIN" ]; then
    log_success "Ingress configured correctly for $DOMAIN"
else
    log_warning "Ingress host mismatch: expected $DOMAIN, got $INGRESS_HOST"
fi

# Test 6: SSL Certificate
log_info "🔒 Testing SSL Certificate..."
SSL_RESPONSE=$(curl -s -I "https://$DOMAIN" | head -1)
if echo "$SSL_RESPONSE" | grep -q "200"; then
    log_success "SSL certificate working"
else
    log_warning "SSL certificate may have issues"
fi

# Test 7: Game Files
log_info "🎮 Testing Game Files..."
GAME_JS_RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$DOMAIN/asteroids.js")
if [ "$GAME_JS_RESPONSE" = "200" ]; then
    log_success "Game JavaScript file accessible"
else
    log_warning "Game JavaScript file not accessible (HTTP $GAME_JS_RESPONSE)"
fi

echo
log_info "📊 Migration Summary:"
echo "===================="

# Overall assessment
TESTS_PASSED=0
TOTAL_TESTS=7

# Count successful tests
[ "$WEB_RESPONSE" = "200" ] && ((TESTS_PASSED++))
echo "$API_RESPONSE" | grep -q '\[' && ((TESTS_PASSED++))
[ "$DB_COUNT" -gt 0 ] && ((TESTS_PASSED++))
[ "$FRONTEND_READY" -gt 0 ] && [ "$API_READY" -gt 0 ] && [ "$DB_READY" -gt 0 ] && ((TESTS_PASSED++))
[ "$INGRESS_HOST" = "$DOMAIN" ] && ((TESTS_PASSED++))
echo "$SSL_RESPONSE" | grep -q "200" && ((TESTS_PASSED++))
[ "$GAME_JS_RESPONSE" = "200" ] && ((TESTS_PASSED++))

echo "Tests passed: $TESTS_PASSED/$TOTAL_TESTS"

if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    log_success "🎉 Migration completed successfully!"
    echo
    log_info "✅ All systems operational:"
    echo "• Web interface: https://$DOMAIN"
    echo "• High scores preserved and accessible"
    echo "• Database connectivity working"
    echo "• All pods running correctly"
    echo "• SSL certificate valid"
    echo "• Game files accessible"
    echo
    log_info "🎮 Ready to play!"
    echo "1. Visit: https://$DOMAIN"
    echo "2. Click the sound toggle (🔇) to enable audio"
    echo "3. Use arrow keys to move, spacebar to shoot"
    echo "4. Your high scores are preserved!"
    
elif [ $TESTS_PASSED -ge 5 ]; then
    log_warning "Migration mostly successful with minor issues"
    echo "The game should be playable, but some features may need attention."
    
else
    log_error "Migration has significant issues"
    echo "Please check the failed tests and troubleshoot accordingly."
fi

echo
log_info "🔧 Useful Commands:"
echo "kubectl get pods -n default | grep asteroid"
echo "kubectl logs -n default -l app=asteroids-game -f"
echo "kubectl logs -n default -l app=asteroids-api -f"
