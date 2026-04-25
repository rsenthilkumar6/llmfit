#!/bin/bash
# llmfit-server-managed.sh
# Runs llmfit serve and auto-exits after IDLE_MINUTES of no requests.
# Frees ~200MB of RAM when idle.

set -euo pipefail

LLMFIT_BIN="${LLMFIT_BIN:-/Users/rajamans/workspace/dev/repos/personal/llmfit/target/release/llmfit}"
HOST="${LLMFIT_HOST:-127.0.0.1}"
PORT="${LLMFIT_PORT:-8787}"
IDLE_MINUTES="${LLMFIT_IDLE_MINUTES:-15}"
LOG_FILE="${LLMFIT_LOG_FILE:-/Users/rajamans/workspace/logs/llmfit-server.log}"
LAST_REQUEST_FILE="/tmp/llmfit-last-request"
READY_FILE="/tmp/llmfit-server.ready"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

is_server_responding() {
    curl -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1
}

update_last_request() {
    date +%s > "$LAST_REQUEST_FILE"
}

start_server() {
    log "llmfit-server starting (idle timeout: ${IDLE_MINUTES}m, port: $PORT)"

    "$LLMFIT_BIN" serve --host "$HOST" --port "$PORT" >> "$LOG_FILE" 2>&1 &
    LLMFIT_PID=$!
    log "PID: $LLMFIT_PID"

    if ! kill -0 "$LLMFIT_PID" 2>/dev/null; then
        log "FATAL: llmfit-server process exited immediately (check $LOG_FILE)"
        return 1
    fi

    update_last_request
    echo "$LLMFIT_PID" > "$READY_FILE"
}

wait_for_server() {
    local waited=0
    while [ $waited -lt 30 ]; do
        if is_server_responding; then
            log "Server is up and responding on port $PORT"
            return 0
        fi
        sleep 2
        waited=$(( waited + 2 ))
    done
    log "FATAL: Server did not respond on port $PORT within 30s"
    return 1
}

monitor_loop() {
    local LLMFIT_PID
    LLMFIT_PID=$(cat "$READY_FILE")

    while kill -0 "$LLMFIT_PID" 2>/dev/null; do
        sleep 60

        if is_server_responding; then
            update_last_request
        fi

        LAST_REQ=$(cat "$LAST_REQUEST_FILE" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        IDLE_SECS=$(( NOW - LAST_REQ ))
        IDLE_LIMIT=$(( IDLE_MINUTES * 60 ))

        if [ "$IDLE_SECS" -gt "$IDLE_LIMIT" ]; then
            log "Idle for ${IDLE_SECS}s (limit ${IDLE_LIMIT}s) — shutting down to free memory"
            kill "$LLMFIT_PID" 2>/dev/null
            wait "$LLMFIT_PID" 2>/dev/null || true
            log "llmfit-server stopped."
            rm -f "$READY_FILE" "$LAST_REQUEST_FILE"
            exit 0
        fi
    done

    log "llmfit-server process died unexpectedly (check $LOG_FILE)"
    rm -f "$READY_FILE" "$LAST_REQUEST_FILE"
    return 1
}

main() {
    log "=== llmfit-server-managed.sh starting ==="

    if ! start_server; then
        exit 1
    fi

    if ! wait_for_server; then
        log "Killing failed process..."
        kill "$(cat "$READY_FILE")" 2>/dev/null || true
        exit 1
    fi

    log "llmfit-server READY on port $PORT"

    monitor_loop
}

main "$@"