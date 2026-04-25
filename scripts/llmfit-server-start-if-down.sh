#!/bin/bash
# llmfit-server-start-if-down.sh
# Checks if llmfit-server is running on PORT (default 8787).
# If not running, starts it via launchd and waits for it to be ready.
# Used by nginx to lazily start llmfit-server on first request.

set -euo pipefail

PORT="${LLMFIT_PORT:-8787}"
MAX_WAIT="${LLMFIT_MAX_WAIT:-30}"
WAIT_INTERVAL="${LLMFIT_WAIT_INTERVAL:-2}"

is_server_up() {
    curl -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1
}

start_server() {
    launchctl start ai.llmfit.server
}

wait_for_server() {
    local waited=0
    while [ $waited -lt $MAX_WAIT ]; do
        if is_server_up; then
            return 0
        fi
        sleep "$WAIT_INTERVAL"
        waited=$(( waited + WAIT_INTERVAL ))
    done
    return 1
}

main() {
    if is_server_up; then
        exit 0
    fi

    start_server

    if wait_for_server; then
        exit 0
    fi

    exit 1
}

main "$@"