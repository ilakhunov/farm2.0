#!/usr/bin/env bash
# Quick health check script

set -euo pipefail

API_URL="${API_URL:-http://localhost:8000}"

echo "🏥 HEALTH CHECK"
echo "=============="
echo ""

# Check Backend API
echo -n "Backend API: "
if curl -s "$API_URL/health" >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FAILED"
fi

# Check Products API
echo -n "Products API: "
if curl -s "$API_URL/api/v1/products?limit=1" >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FAILED"
fi

# Check Processes
echo -n "Backend Process: "
if ps aux | grep -q "[u]vicorn app.main:app"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

echo -n "Admin Panel: "
if ps aux | grep -q "[v]ite"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

echo -n "Mobile App: "
if ps aux | grep -q "[f]lutter run"; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

# Check Docker
echo -n "PostgreSQL: "
if docker ps | grep -q farm_postgres; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

echo -n "Redis: "
if docker ps | grep -q farm_redis; then
    echo "✅ Running"
else
    echo "❌ Not running"
fi

echo ""
echo "✅ Health check complete!"

