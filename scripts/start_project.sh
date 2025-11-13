#!/usr/bin/env bash
# Universal project startup script for any machine/VM
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 Starting Farm Platform Project"
echo "=================================="

# Setup environment automatically
echo "📋 Setting up environment..."
./scripts/setup_environment.sh

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=30
    local attempt=1

    echo "⏳ Waiting for $service_name to be ready..."
    while ! nc -z "$host" "$port" 2>/dev/null; do
        if [ $attempt -ge $max_attempts ]; then
            echo "❌ $service_name failed to start after $max_attempts attempts"
            return 1
        fi
        echo "   Attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done
    echo "✅ $service_name is ready!"
}

# Start infrastructure (PostgreSQL + Redis)
echo ""
echo "🐳 Starting infrastructure (PostgreSQL + Redis)..."
if command_exists docker && command_exists docker-compose; then
    docker-compose up -d
    echo "⏳ Waiting for databases to be ready..."
    sleep 5
    wait_for_service localhost 5432 "PostgreSQL"
    wait_for_service localhost 6379 "Redis"
else
    echo "❌ Docker or docker-compose not found. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Run database migrations
echo ""
echo "🗃️  Setting up database..."
cd "$PROJECT_ROOT/backend"
if command_exists poetry; then
    poetry install

    # Create initial migration if it doesn't exist
    if [ ! -d "alembic/versions" ] || [ -z "$(ls -A alembic/versions)" ]; then
        echo "📝 Creating initial database migration..."
        poetry run alembic revision --autogenerate -m "Initial migration"
    fi

    echo "⬆️  Applying database migrations..."
    poetry run alembic upgrade head
else
    echo "❌ Poetry not found. Please install Poetry first."
    echo "   Visit: https://python-poetry.org/docs/#installation/"
    exit 1
fi

# PID file for process management
PID_FILE="$PROJECT_ROOT/.project_pids"
rm -f "$PID_FILE"

# Start backend in background
echo ""
echo "🔧 Starting backend server..."
cd "$PROJECT_ROOT/backend"
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/farm_backend.log 2>&1 &
BACKEND_PID=$!
echo "$BACKEND_PID" >> "$PID_FILE"
echo "✅ Backend started (PID: $BACKEND_PID)"

# Wait for backend to be ready
wait_for_service 0.0.0.0 8000 "Backend API"

# Start admin panel in background
echo ""
echo "🖥️  Starting admin panel..."
cd "$PROJECT_ROOT/admin"
if command_exists npm; then
    npm install > /dev/null 2>&1
    npm run dev > /tmp/farm_admin.log 2>&1 &
    ADMIN_PID=$!
    echo "$ADMIN_PID" >> "$PID_FILE"
    echo "✅ Admin panel started (PID: $ADMIN_PID)"
else
    echo "⚠️  npm not found. Skipping admin panel startup."
    echo "   To start manually: cd admin && npm install && npm run dev"
fi

# Start mobile development server (optional)
echo ""
echo "📱 Starting mobile app..."
cd "$PROJECT_ROOT/mobile"
if command_exists flutter; then
    flutter pub get > /dev/null 2>&1
    flutter run -d linux > /tmp/farm_mobile.log 2>&1 &
    MOBILE_PID=$!
    echo "$MOBILE_PID" >> "$PID_FILE"
    echo "✅ Mobile app started (PID: $MOBILE_PID)"
    echo "   Logs: tail -f /tmp/farm_mobile.log"
else
    echo "⚠️  Flutter not found. Skipping mobile app startup."
    echo "   Install Flutter: https://flutter.dev/docs/get-started/install"
fi

echo ""
echo "🎉 Project startup complete!"
echo "============================"
echo ""
echo "🌐 Services running:"
LOCAL_IP=$(grep "API_HOST" backend/.env 2>/dev/null | cut -d'=' -f2 || echo "10.201.175.112")
if [ "$LOCAL_IP" = "0.0.0.0" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
fi
echo "   • Backend API:    http://$LOCAL_IP:8000"
echo "   • API Docs:       http://$LOCAL_IP:8000/docs"
if [ -n "${ADMIN_PID:-}" ]; then
    echo "   • Admin Panel:    http://$LOCAL_IP:5174"
fi
if [ -n "${MOBILE_PID:-}" ]; then
    echo "   • Mobile App:     Running on Linux desktop"
fi
echo ""
echo "🛑 To stop all services:"
echo "   ./scripts/stop_project.sh"
echo ""
echo "📝 Useful commands:"
echo "   • View logs:       docker-compose logs -f"
echo "   • Backend logs:    tail -f /tmp/farm_backend.log"
echo "   • Admin logs:      tail -f /tmp/farm_admin.log"
echo "   • Mobile logs:      tail -f /tmp/farm_mobile.log"
echo "   • Reset DB:        docker-compose down -v && docker-compose up -d"
echo "   • Run tests:       cd backend && poetry run pytest"
echo ""
echo "Happy coding! 🚀"
