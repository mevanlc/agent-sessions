#!/bin/bash
# Removes the AgentSessions index database so the next run starts from scratch.
# Usage: bash reset-index.sh

set -euo pipefail

DB="$HOME/Library/Application Support/AgentSessions/index.db"

if [ -f "$DB" ]; then
    rm -f "$DB" "${DB}-wal" "${DB}-shm"
    echo "Removed: $DB (+ WAL/SHM)"
else
    echo "No index found at: $DB"
fi
