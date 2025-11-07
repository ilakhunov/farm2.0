#!/usr/bin/env bash
# Check dependencies and integration between stacks
set -euo pipefail

PROJECT_ROOT="/home/tandyvip/projects/farm2.0"
ERRORS=0

echo "==== Checking Backend Dependencies ===="
cd "$PROJECT_ROOT/backend"
if [ -f "pyproject.toml" ]; then
  echo "✓ pyproject.toml found"
  if grep -q "fastapi" pyproject.toml; then
    echo "✓ FastAPI dependency found"
  else
    echo "✗ FastAPI not found"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "✗ pyproject.toml not found"
  ERRORS=$((ERRORS + 1))
fi

echo ""
echo "==== Checking Mobile Dependencies ===="
cd "$PROJECT_ROOT/mobile"
if [ -f "pubspec.yaml" ]; then
  echo "✓ pubspec.yaml found"
  if grep -q "dio:" pubspec.yaml; then
    echo "✓ Dio dependency found"
  else
    echo "✗ Dio not found"
    ERRORS=$((ERRORS + 1))
  fi
  if grep -q "equatable:" pubspec.yaml; then
    echo "✓ Equatable dependency found"
  else
    echo "✗ Equatable not found"
    ERRORS=$((ERRORS + 1))
  fi
  if grep -q "url_launcher:" pubspec.yaml; then
    echo "✓ url_launcher dependency found"
  else
    echo "✗ url_launcher not found"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "✗ pubspec.yaml not found"
  ERRORS=$((ERRORS + 1))
fi

echo ""
echo "==== Checking Admin Dependencies ===="
cd "$PROJECT_ROOT/admin"
if [ -f "package.json" ]; then
  echo "✓ package.json found"
  if grep -q "axios" package.json; then
    echo "✓ Axios dependency found"
  else
    echo "✗ Axios not found"
    ERRORS=$((ERRORS + 1))
  fi
  if grep -q "react" package.json; then
    echo "✓ React dependency found"
  else
    echo "✗ React not found"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "✗ package.json not found"
  ERRORS=$((ERRORS + 1))
fi

echo ""
echo "==== Checking API Integration ===="
cd "$PROJECT_ROOT"

# Check if mobile uses correct API base URL
if grep -q "kApiBaseUrl" mobile/lib/core/constants/env.dart 2>/dev/null; then
  echo "✓ Mobile API constant defined"
else
  echo "✗ Mobile API constant missing"
  ERRORS=$((ERRORS + 1))
fi

# Check if admin uses correct API base URL
if grep -q "__API_BASE_URL__" admin/src/lib/api-client.ts 2>/dev/null; then
  echo "✓ Admin API constant defined"
else
  echo "✗ Admin API constant missing"
  ERRORS=$((ERRORS + 1))
fi

# Check if backend has all required endpoints
ENDPOINTS=("auth" "users" "products" "orders" "payments" "deliveries")
for endpoint in "${ENDPOINTS[@]}"; do
  if [ -f "backend/app/api/v1/${endpoint}.py" ]; then
    echo "✓ Backend endpoint /api/v1/${endpoint} exists"
  else
    echo "✗ Backend endpoint /api/v1/${endpoint} missing"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
echo "==== Checking Database Models ===="
MODELS=("user" "otp" "product" "order" "transaction" "delivery")
for model in "${MODELS[@]}"; do
  if [ -f "backend/app/models/${model}.py" ]; then
    echo "✓ Model ${model} exists"
  else
    echo "✗ Model ${model} missing"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "✓ All dependency checks passed!"
  exit 0
else
  echo "✗ Found $ERRORS errors"
  exit 1
fi
