#!/usr/bin/env bash
# Scan idea threads and produce a status report.
# Usage: thread-report.sh <project-path>

set -euo pipefail

PROJECT_DIR="$1"
THREADS_DIR="$PROJECT_DIR/researcher/threads"

if [ ! -d "$THREADS_DIR" ]; then
  echo "No threads directory found at $THREADS_DIR" >&2
  exit 1
fi

echo "THREAD STATUS"
echo ""
printf "| %-25s | %-10s | %5s | %6s |\n" "Thread" "Status" "Notes" "Open Q"
printf "| %-25s | %-10s | %5s | %6s |\n" "-------------------------" "----------" "-----" "------"

TOTAL=0; ACTIVE=0; PARKED=0; DEAD=0; MERGED=0

for thread_dir in "$THREADS_DIR"/*/; do
  [ -d "$thread_dir" ] || continue
  TOTAL=$((TOTAL + 1))
  thread=$(basename "$thread_dir")
  status="active"; notes=0; open_q=0

  if [ -f "$thread_dir/status.md" ]; then
    status=$(grep -i 'status:' "$thread_dir/status.md" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d ' ' || echo "active")
  fi

  if [ -f "$thread_dir/raw-notes.md" ]; then
    notes=$(wc -l < "$thread_dir/raw-notes.md" | tr -d ' ')
  fi

  if [ -f "$thread_dir/questions.md" ]; then
    open_q=$(grep -c '^\- \[ \]' "$thread_dir/questions.md" 2>/dev/null || echo 0)
  fi

  case "$status" in
    active) ACTIVE=$((ACTIVE + 1)) ;;
    parked) PARKED=$((PARKED + 1)) ;;
    dead*) DEAD=$((DEAD + 1)) ;;
    merged*) MERGED=$((MERGED + 1)) ;;
  esac

  printf "| %-25s | %-10s | %5s | %6s |\n" "$thread" "$status" "$notes" "$open_q"
done

echo ""
echo "TOTAL: $TOTAL threads — $ACTIVE active, $PARKED parked, $DEAD dead-end, $MERGED merged"
