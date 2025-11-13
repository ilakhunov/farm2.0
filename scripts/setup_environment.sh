#!/usr/bin/env bash
# Auto-detect local IP and setup environment variables
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Project root: $PROJECT_ROOT"

# Function to get local IP address
get_local_ip() {
    # Try different methods to get local IP
    local ip=""

    # Method 1: Use hostname -I (Linux)
    if command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I | awk '{print $1}')
    fi

    # Method 2: Use ip route (Linux)
    if [ -z "$ip" ] && command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1 {print $7}')
    fi

    # Method 3: Use ifconfig (fallback)
    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | sed 's/addr://')
    fi

    # Method 4: macOS ifconfig
    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)
    fi

    # Fallback to localhost if nothing found
    if [ -z "$ip" ]; then
        echo "Warning: Could not detect local IP, using localhost"
        ip="localhost"
    fi

    echo "$ip"
}

# Function to generate random secret key
generate_secret_key() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 32
    else
        # Fallback: use /dev/urandom or date
        head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 || date | md5sum | cut -d' ' -f1
    fi
}

# Detect local IP
LOCAL_IP=$(get_local_ip)
echo "Detected local IP: $LOCAL_IP"

# Generate secret key if not exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    SECRET_KEY=$(generate_secret_key)
    echo "Generated secret key: ${SECRET_KEY:0:16}..."
else
    # Extract existing secret key
    SECRET_KEY=$(grep '^SECRET_KEY=' "$PROJECT_ROOT/.env" | cut -d'=' -f2 || echo "")
    if [ -z "$SECRET_KEY" ]; then
        SECRET_KEY=$(generate_secret_key)
        echo "Generated new secret key: ${SECRET_KEY:0:16}..."
    fi
fi

# Create .env file
cat > "$PROJECT_ROOT/.env" << EOF
# Auto-generated environment configuration
# Generated on $(date) for IP: $LOCAL_IP

# Backend Configuration
SECRET_KEY=$SECRET_KEY
DATABASE_URL=postgresql+asyncpg://postgres:postgres@$LOCAL_IP:5432/farm
REDIS_URL=redis://$LOCAL_IP:6379/0

# API Configuration
API_HOST=$LOCAL_IP
API_PORT=8000
API_BASE_URL=http://$LOCAL_IP:8000/api/v1

# Frontend Configuration
VITE_API_BASE_URL=http://$LOCAL_IP:8000/api/v1

# SMS Configuration (dev mode for local development)
SMS_PROVIDER=dev
SMS_DEBUG_ECHO=true

# CORS Configuration
ALLOWED_HOSTS=http://$LOCAL_IP:3000,http://$LOCAL_IP:5173,http://localhost:3000,http://localhost:5173
EOF

echo "Created .env file at $PROJECT_ROOT/.env"

# Create backend .env file (backend needs it in its own directory)
# Note: DATABASE_URL and REDIS_URL use localhost because backend connects to Docker containers locally
cat > "$PROJECT_ROOT/backend/.env" << EOF
# Backend environment configuration
# Generated on $(date) for IP: $LOCAL_IP

SECRET_KEY=$SECRET_KEY
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/farm
REDIS_URL=redis://localhost:6379/0
API_HOST=0.0.0.0
API_PORT=8000
SMS_PROVIDER=dev
SMS_DEBUG_ECHO=true
PAYMENT_MOCK_MODE=true
ALLOWED_HOSTS=http://$LOCAL_IP:3000,http://$LOCAL_IP:5173,http://localhost:3000,http://localhost:5173
EOF

echo "Created backend/.env file"

# Create mobile environment file
cat > "$PROJECT_ROOT/mobile/.env" << EOF
# Mobile app environment
API_BASE_URL=http://$LOCAL_IP:8000/api/v1
EOF

echo "Created mobile/.env file"

# Update mobile API base URL in code (for compile-time constant)
sed -i "s|defaultValue: 'http://[^']*'|defaultValue: 'http://$LOCAL_IP:8000/api/v1'|g" "$PROJECT_ROOT/mobile/lib/core/constants/env.dart" 2>/dev/null || true
echo "Updated mobile API base URL in env.dart"

# Create admin environment file
cat > "$PROJECT_ROOT/admin/.env" << EOF
# Admin panel environment
VITE_API_BASE_URL=http://$LOCAL_IP:8000/api/v1
EOF

echo "Created admin/.env file"

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Local IP detected: $LOCAL_IP"
echo "API will be available at: http://$LOCAL_IP:8000"
echo "Admin panel will be available at: http://$LOCAL_IP:5173"
echo ""
echo "To start the project:"
echo "1. Start infrastructure: docker-compose up -d"
echo "2. Start backend: cd backend && poetry run uvicorn app.main:app --reload --host 0.0.0.0"
echo "3. Start admin: cd admin && npm run dev"
echo "4. Start mobile: cd mobile && flutter run"
