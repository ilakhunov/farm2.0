#!/usr/bin/env bash
# Real-time log monitoring script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_TYPE="${1:-all}"

case "$LOG_TYPE" in
    backend|b)
        echo -e "${BLUE}📋 Backend API Logs (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        tail -f /tmp/farm_backend.log 2>/dev/null || echo "Лог файл не найден"
        ;;
    admin|a)
        echo -e "${BLUE}📋 Admin Panel Logs (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        tail -f /tmp/farm_admin.log 2>/dev/null || echo "Лог файл не найден"
        ;;
    mobile|m)
        echo -e "${BLUE}📋 Mobile App Logs (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        tail -f /tmp/farm_mobile.log 2>/dev/null || echo "Лог файл не найден"
        ;;
    docker|d)
        echo -e "${BLUE}📋 Docker Containers Logs (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        docker-compose logs -f 2>/dev/null || echo "Docker Compose не найден"
        ;;
    errors|e)
        echo -e "${RED}⚠️  Errors Only (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        tail -f /tmp/farm_backend.log /tmp/farm_admin.log /tmp/farm_mobile.log 2>/dev/null | grep --line-buffered -iE "(error|exception|failed|warning)" || echo "Ошибок не обнаружено"
        ;;
    all|*)
        echo -e "${BLUE}📋 All Logs (Real-time)${NC}"
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        echo ""
        echo -e "${CYAN}Backend:${NC}"
        tail -f /tmp/farm_backend.log 2>/dev/null &
        BACKEND_PID=$!
        
        echo -e "${CYAN}Admin:${NC}"
        tail -f /tmp/farm_admin.log 2>/dev/null &
        ADMIN_PID=$!
        
        echo -e "${CYAN}Mobile:${NC}"
        tail -f /tmp/farm_mobile.log 2>/dev/null &
        MOBILE_PID=$!
        
        # Wait for all processes
        trap "kill $BACKEND_PID $ADMIN_PID $MOBILE_PID 2>/dev/null; exit" INT TERM
        wait
        ;;
esac

