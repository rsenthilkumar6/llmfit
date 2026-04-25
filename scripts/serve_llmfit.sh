#!/bin/bash

APP_NAME="llmfit"
LOG_DIR="$HOME/workspace/logs"
TIMESTAMP=$(date +"%d-%m-%Y-%H%M%S")
LOG_FILE="$LOG_DIR/${APP_NAME}_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$SCRIPT_DIR/../target/release/llmfit" serve --host 0.0.0.0 --port 8787 2>&1 | tee -a "$LOG_FILE"