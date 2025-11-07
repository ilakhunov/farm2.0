#!/usr/bin/env bash
# Create Alembic migration for all models
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Creating Alembic migration..."

# Check if .env exists
if [ ! -f .env ]; then
  echo "Creating .env from defaults..."
  cat > .env <<ENVEOF
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/farm
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
SMS_PROVIDER=dev
SMS_DEBUG_ECHO=true
ENVEOF
  echo "✓ .env created"
fi

# Try to use poetry if available, otherwise use python directly
if command -v poetry &> /dev/null; then
  echo "Using Poetry..."
  poetry run alembic revision --autogenerate -m "Initial migration: all models"
  echo "✓ Migration created"
else
  echo "Poetry not found. Using Python directly..."
  if python3 -c "import alembic" 2>/dev/null; then
    python3 -m alembic revision --autogenerate -m "Initial migration: all models"
    echo "✓ Migration created"
  else
    echo "⚠️  Alembic not installed. Please install dependencies first"
    exit 1
  fi
fi
