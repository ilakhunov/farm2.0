#!/usr/bin/env bash
# Add Poetry to PATH for current session
export PATH="$HOME/.local/bin:$PATH"

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry не установлен. Устанавливаю..."
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "Poetry версия: $(poetry --version)"
echo "✓ Poetry готов к использованию"
