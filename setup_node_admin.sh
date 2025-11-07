#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/tandyvip/projects/farm2.0"
ADMIN_DIR="$PROJECT_ROOT/admin"
MIN_NODE_MAJOR=18

need_node_install() {
  if ! command -v node >/dev/null 2>&1; then
    return 0
  fi
  local version
  version=$(node -v | sed 's/^v//')
  local major=${version%%.*}
  if (( major < MIN_NODE_MAJOR )); then
    return 0
  fi
  return 1
}

if need_node_install; then
  echo "Installing Node.js via NodeSource (requires sudo)..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js $(node -v) already satisfies requirement"
fi

echo "Cleaning admin dependencies..."
rm -rf "$ADMIN_DIR/node_modules" "$ADMIN_DIR/package-lock.json"

cd "$ADMIN_DIR"
echo "Running npm install..."
npm install

echo "Running npm run lint..."
npm run lint

echo "Setup complete."
