#!/usr/bin/env bash
# Simple system health check script
set -euo pipefail

printf '\n==== System Information ===='\n
uname -a
printf '\nUptime: '\n
uptime

printf '\n==== CPU / Memory Usage ===='\n
LC_ALL=C top -b -n1 | head -n5

printf '\n==== Memory Details (free -h) ===='\n
free -h

printf '\n==== Disk Usage (df -h) ===='\n
df -h | grep -E "Filesystem|/dev/sd|/dev/nv|/dev/mmc"

printf '\n==== Top Processes (ps aux --sort=-%cpu | head) ===='\n
ps aux --sort=-%cpu | head -n 11

printf '\n==== Docker Containers (if any) ===='\n
if command -v docker >/dev/null 2>&1; then
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" || echo "Docker running but docker ps failed"
else
  echo "Docker not installed"
fi

printf '\n==== Node / npm Processes ===='\n
pgrep -af "node|npm" || echo "No node/npm processes"

printf '\n==== Flutter Processes ===='\n
pgrep -af "flutter" || echo "No flutter processes"

printf '\nHealth check complete.\n'
