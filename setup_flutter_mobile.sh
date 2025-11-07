#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/tandyvip/projects/farm2.0"
MOBILE_DIR="$PROJECT_ROOT/mobile"
BACKUP_DIR="$(mktemp -d)"

backup_if_exists() {
  local path="$1"
  local name="$2"
  if [[ -e "$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$name")"
    cp -a "$path" "$BACKUP_DIR/$name"
  fi
}

backup_if_exists "$MOBILE_DIR/lib" "lib"
backup_if_exists "$MOBILE_DIR/pubspec.yaml" "pubspec.yaml"
backup_if_exists "$MOBILE_DIR/assets/translations" "assets/translations"
backup_if_exists "$MOBILE_DIR/README.md" "README.md"

if [[ -d "$MOBILE_DIR" ]]; then
  rm -rf "$MOBILE_DIR"
fi

cd "$PROJECT_ROOT"
flutter create mobile

if [[ -d "$BACKUP_DIR/lib" ]]; then
  rm -rf "$MOBILE_DIR/lib"
  cp -a "$BACKUP_DIR/lib" "$MOBILE_DIR/lib"
fi

if [[ -d "$BACKUP_DIR/assets" ]]; then
  mkdir -p "$MOBILE_DIR/assets"
  cp -a "$BACKUP_DIR/assets/." "$MOBILE_DIR/assets/"
fi

if [[ -f "$BACKUP_DIR/pubspec.yaml" ]]; then
  cp "$BACKUP_DIR/pubspec.yaml" "$MOBILE_DIR/pubspec.yaml"
fi

if [[ -f "$BACKUP_DIR/README.md" ]]; then
  cp "$BACKUP_DIR/README.md" "$MOBILE_DIR/README.md"
fi

cd "$MOBILE_DIR"
flutter pub get

echo "Flutter mobile project scaffolded successfully."
