#!/usr/bin/env bash
# =============================================================================
# build-repo — llmfit Build Script
# Usage: ./build-repo.sh
# =============================================================================


echo "Building $(basename "$(pwd)")"

echo "Compilation"
cargo build --release

echo "Full project build complete."
