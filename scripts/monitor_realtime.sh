#!/usr/bin/env bash
# Real-time monitoring and diagnostics script

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check service status
check_service() {
    local service=$1
    local check_cmd=$2
    
    if eval "$check_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $service"
        return 0
    else
        echo -e "${RED}❌${NC} $service"
        return 1
    fi
}

# Function to get service metrics
get_metrics() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  REAL-TIME DIAGNOSTICS${NC}"
    echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    
    # Service Status
    echo -e "${YELLOW}📊 SERVICE STATUS:${NC}"
    check_service "Backend API" "curl -s http://localhost:8000/health >/dev/null"
    check_service "Admin Panel" "ps aux | grep -q '[v]ite'"
    check_service "Mobile App" "ps aux | grep -q '[f]lutter run'"
    check_service "PostgreSQL" "docker ps | grep -q farm_postgres"
    check_service "Redis" "docker ps | grep -q farm_redis"
    
    echo ""
    
    # API Metrics
    echo -e "${YELLOW}📈 API METRICS:${NC}"
    if curl -s http://localhost:8000/health >/dev/null 2>&1; then
        PRODUCTS_COUNT=$(curl -s "http://localhost:8000/api/v1/products?limit=1" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('total', 0))" 2>/dev/null || echo "0")
        echo "  • Products in DB: $PRODUCTS_COUNT"
        
        ORDERS_COUNT=$(docker exec farm_postgres psql -U postgres -d farm -t -c "SELECT COUNT(*) FROM orders;" 2>/dev/null | tr -d ' ' || echo "0")
        echo "  • Orders in DB: $ORDERS_COUNT"
        
        USERS_COUNT=$(docker exec farm_postgres psql -U postgres -d farm -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ' || echo "0")
        echo "  • Users in DB: $USERS_COUNT"
    else
        echo "  • API недоступен"
    fi
    
    echo ""
    
    # Process Info
    echo -e "${YELLOW}🖥️  PROCESSES:${NC}"
    BACKEND_PID=$(ps aux | grep "[u]vicorn app.main:app" | awk '{print $2}' | head -1)
    if [ -n "$BACKEND_PID" ]; then
        BACKEND_CPU=$(ps -p "$BACKEND_PID" -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")
        BACKEND_MEM=$(ps -p "$BACKEND_PID" -o %mem= 2>/dev/null | tr -d ' ' || echo "0")
        echo "  • Backend (PID $BACKEND_PID): CPU ${BACKEND_CPU}%, MEM ${BACKEND_MEM}%"
    fi
    
    ADMIN_PID=$(ps aux | grep "[v]ite" | grep admin | awk '{print $2}' | head -1)
    if [ -n "$ADMIN_PID" ]; then
        ADMIN_CPU=$(ps -p "$ADMIN_PID" -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")
        ADMIN_MEM=$(ps -p "$ADMIN_PID" -o %mem= 2>/dev/null | tr -d ' ' || echo "0")
        echo "  • Admin Panel (PID $ADMIN_PID): CPU ${ADMIN_CPU}%, MEM ${ADMIN_MEM}%"
    fi
    
    FLUTTER_PID=$(ps aux | grep "[f]lutter run" | awk '{print $2}' | head -1)
    if [ -n "$FLUTTER_PID" ]; then
        FLUTTER_CPU=$(ps -p "$FLUTTER_PID" -o %cpu= 2>/dev/null | tr -d ' ' || echo "0")
        FLUTTER_MEM=$(ps -p "$FLUTTER_PID" -o %mem= 2>/dev/null | tr -d ' ' || echo "0")
        echo "  • Mobile App (PID $FLUTTER_PID): CPU ${FLUTTER_CPU}%, MEM ${FLUTTER_MEM}%"
    fi
    
    echo ""
    
    # Docker Containers
    echo -e "${YELLOW}🐳 DOCKER CONTAINERS:${NC}"
    if docker ps | grep -q farm_postgres; then
        POSTGRES_STATUS=$(docker inspect farm_postgres --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
        echo "  • PostgreSQL: $POSTGRES_STATUS"
    fi
    
    if docker ps | grep -q farm_redis; then
        REDIS_STATUS=$(docker inspect farm_redis --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
        echo "  • Redis: $REDIS_STATUS"
    fi
    
    echo ""
    
    # Recent Errors
    echo -e "${YELLOW}⚠️  RECENT ERRORS (last 3):${NC}"
    BACKEND_ERRORS=$(tail -50 /tmp/farm_backend.log 2>/dev/null | grep -iE "(error|exception|failed)" | tail -3 || echo "")
    if [ -n "$BACKEND_ERRORS" ]; then
        echo "  Backend:"
        echo "$BACKEND_ERRORS" | sed 's/^/    /'
    else
        echo "  Backend: нет ошибок"
    fi
    
    MOBILE_ERRORS=$(tail -50 /tmp/farm_mobile.log 2>/dev/null | grep -iE "(error|exception|failed|Build process failed)" | tail -3 || echo "")
    if [ -n "$MOBILE_ERRORS" ]; then
        echo "  Mobile:"
        echo "$MOBILE_ERRORS" | sed 's/^/    /'
    else
        echo "  Mobile: нет ошибок"
    fi
    
    echo ""
    
    # Port Status
    echo -e "${YELLOW}🔌 PORTS:${NC}"
    if netstat -tuln 2>/dev/null | grep -q ":8000" || ss -tuln 2>/dev/null | grep -q ":8000"; then
        echo "  • 8000 (Backend): ✅ занят"
    else
        echo "  • 8000 (Backend): ❌ свободен"
    fi
    
    ADMIN_PORT=$(ps aux | grep "[v]ite" | grep -oP '--port \K\d+' | head -1 || echo "unknown")
    if [ "$ADMIN_PORT" != "unknown" ]; then
        if netstat -tuln 2>/dev/null | grep -q ":$ADMIN_PORT" || ss -tuln 2>/dev/null | grep -q ":$ADMIN_PORT"; then
            echo "  • $ADMIN_PORT (Admin): ✅ занят"
        else
            echo "  • $ADMIN_PORT (Admin): ❌ свободен"
        fi
    else
        echo "  • Admin Panel: порт не определен"
    fi
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

# Main loop
if [ "${1:-}" == "--once" ]; then
    # Run once
    get_metrics
else
    # Continuous monitoring
    clear
    while true; do
        get_metrics
        echo ""
        echo "Обновление через 5 секунд... (Ctrl+C для выхода)"
        sleep 5
        clear
    done
fi
