#!/usr/bin/env bash
# =============================================================================
# build-repo — llmfit Build Script
# Usage: ./build-repo.sh
# =============================================================================

# 1. Source the engine
source "$HOME/.local/bin/build-engine"

info "Building $(basename "$(pwd)")"

# 2. Define your specific build steps
run_step "Updates" "repo --latest"
run_step "Compilation" "cargo build --release"
# run_step "Testing" "make test"
# run_step "Protobufs" "make protos"
# run_step "Installation" "make install"

success "Full project build complete."
