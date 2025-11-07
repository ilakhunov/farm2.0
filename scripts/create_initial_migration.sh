#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../backend"

if ! command -v poetry >/dev/null 2>&1; then
  echo "Poetry not found. Install it first: https://python-poetry.org/docs/#installation"
  exit 1
fi

echo "Generating initial migration..."
poetry run alembic revision --autogenerate -m "Initial migration: users and phone_otps"

echo "Migration created. Apply it with:"
echo "  cd backend && poetry run alembic upgrade head"
