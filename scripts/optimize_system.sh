#!/usr/bin/env bash
# System optimization script
set -euo pipefail

echo "==== Stopping Gradle daemons ===="
if command -v gradle >/dev/null 2>&1; then
  gradle --stop 2>/dev/null || echo "Gradle not running or already stopped"
fi

# Kill Gradle processes if they exist
pkill -f "GradleDaemon" 2>/dev/null && echo "Killed Gradle daemon processes" || echo "No Gradle daemons found"

echo ""
echo "==== Stopping Kotlin compiler daemons ===="
pkill -f "KotlinCompileDaemon" 2>/dev/null && echo "Killed Kotlin daemon processes" || echo "No Kotlin daemons found"

echo ""
echo "==== Checking memory after cleanup ===="
free -h

echo ""
echo "==== Recommendations ===="
echo "1. Restart Cursor IDE to free Java Language Server memory"
echo "2. Disable Java/Kotlin extensions in Cursor if not needed"
echo "3. Close unused browser tabs"
echo "4. Consider increasing swap if you work with Java projects often"
