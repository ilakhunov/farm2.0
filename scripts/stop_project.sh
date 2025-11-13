#!/usr/bin/env bash
# Stop Farm Platform Project - gracefully shutdown all services
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$PROJECT_ROOT/.project_pids"

echo "🛑 Stopping Farm Platform Project"
echo "==================================="

# Function to check if process is running
is_process_running() {
    local pid=$1
    kill -0 "$pid" 2>/dev/null
}

# Function to stop process gracefully
stop_process() {
    local pid=$1
    local name=$2
    
    if is_process_running "$pid"; then
        echo "⏳ Stopping $name (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        
        # Wait up to 5 seconds for graceful shutdown
        local count=0
        while is_process_running "$pid" && [ $count -lt 5 ]; do
            sleep 1
            ((count++))
        done
        
        # Force kill if still running
        if is_process_running "$pid"; then
            echo "⚠️  Force stopping $name..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        echo "✅ $name stopped"
    else
        echo "ℹ️  $name is not running"
    fi
}

# Stop processes from PID file (if exists)
if [ -f "$PID_FILE" ]; then
    echo ""
    echo "📋 Stopping processes from PID file..."
    while IFS= read -r pid; do
        if [ -n "$pid" ]; then
            # Try to identify process by checking command
            if ps -p "$pid" >/dev/null 2>&1; then
                CMD=$(ps -p "$pid" -o cmd= | head -1)
                if echo "$CMD" | grep -q "uvicorn"; then
                    stop_process "$pid" "Backend API"
                elif echo "$CMD" | grep -q "vite"; then
                    stop_process "$pid" "Admin Panel"
                elif echo "$CMD" | grep -q "flutter"; then
                    stop_process "$pid" "Mobile App"
                else
                    stop_process "$pid" "Process"
                fi
            fi
        fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
else
    echo "ℹ️  PID file not found, searching for processes..."
    
    # Stop backend processes
    echo ""
    echo "🔧 Stopping backend processes..."
    BACKEND_PIDS=$(pgrep -f "uvicorn app.main:app" 2>/dev/null || true)
    if [ -n "$BACKEND_PIDS" ]; then
        for pid in $BACKEND_PIDS; do
            if is_process_running "$pid"; then
                stop_process "$pid" "Backend API"
            fi
        done
    else
        echo "ℹ️  Backend API is not running"
    fi
    
    # Stop admin panel processes
    echo ""
    echo "🖥️  Stopping admin panel processes..."
    ADMIN_PIDS=$(pgrep -f "vite" 2>/dev/null || true)
    if [ -n "$ADMIN_PIDS" ]; then
        for pid in $ADMIN_PIDS; do
            # Check if it's our admin vite process (in admin directory)
            if is_process_running "$pid" && ps -p "$pid" -o cmd= 2>/dev/null | grep -q "admin"; then
                stop_process "$pid" "Admin Panel"
            fi
        done
    else
        echo "ℹ️  Admin Panel is not running"
    fi
fi

# Stop Flutter processes (if any)
echo ""
echo "📱 Stopping Flutter processes..."
FLUTTER_PIDS=$(pgrep -f "flutter run" || true)
if [ -n "$FLUTTER_PIDS" ]; then
    for pid in $FLUTTER_PIDS; do
        stop_process "$pid" "Flutter App"
    done
else
    echo "ℹ️  Flutter App is not running"
fi

# Stop Docker containers
echo ""
echo "🐳 Stopping Docker containers..."
if command -v docker-compose >/dev/null 2>&1; then
    cd "$PROJECT_ROOT"
    docker-compose down
    echo "✅ Docker containers stopped"
else
    echo "⚠️  docker-compose not found, skipping container shutdown"
fi

# Optional: Clean up Docker volumes (commented out by default)
# Uncomment the following lines if you want to remove volumes on stop
# echo ""
# echo "🧹 Cleaning up Docker volumes..."
# docker-compose down -v
# echo "✅ Docker volumes removed"

echo ""
echo "✅ Project stopped successfully!"
echo "================================"
echo ""
echo "📝 Useful commands:"
echo "   • Start project:     ./scripts/start_project.sh"
echo "   • View logs:         docker-compose logs -f"
echo "   • Remove volumes:    docker-compose down -v"
echo "   • Backend logs:      tail -f /tmp/farm_backend.log"
echo "   • Admin logs:        tail -f /tmp/farm_admin.log"
echo ""
