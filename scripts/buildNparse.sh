#!/bin/bash

set -e

LOG_FILE="build_results.log"
TMP_FILE="build_output.txt"

rm -f $LOG_FILE $TMP_FILE

echo "Running Cargo Build..." | tee -a $LOG_FILE
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
git config --global --add safe.directory "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

#stdbuf -oL -eL make build  2>&1 | tee $TMP_FILE || true
#stdbuf -oL -eL cargo build --manifest-path=src/common/Cargo.toml 2>&1 | tee $TMP_FILE || true
#stdbuf -oL -eL cargo build --manifest-path=src/agent/Cargo.toml 2>&1 | tee $TMP_FILE || true
#stdbuf -oL -eL cargo build --manifest-path=src/player/Cargo.toml 2>&1 | tee $TMP_FILE || true
#stdbuf -oL -eL cargo build --manifest-path=src/server/Cargo.toml 2>&1 | tee $TMP_FILE || true
#stdbuf -oL -eL cargo build --manifest-path=src/tools/Cargo.toml 2>&1 | tee $TMP_FILE || true
cargo build -vv --manifest-path=src/common/Cargo.toml | tee $TMP_FILE || true
cargo build -vv --manifest-path=src/agent/Cargo.toml | tee $TMP_FILE || true
cargo build -vv --manifest-path=src/player/Cargo.toml | tee $TMP_FILE || true
cargo build -vv --manifest-path=src/server/Cargo.toml | tee $TMP_FILE || true
cargo build -vv --manifest-path=src/tools/Cargo.toml | tee $TMP_FILE || true

#script -q -f "$TMP_FILE" -c "cargo build --manifest-path=src/common/Cargo.toml"
#script -q -f "$TMP_FILE" -c "cargo build --manifest-path=src/agent/Cargo.toml"
#script -q -f "$TMP_FILE" -c "cargo build --manifest-path=src/player/Cargo.toml"
#script -q -f "$TMP_FILE" -c "cargo build --manifest-path=src/server/Cargo.toml"
#script -q -f "$TMP_FILE" -c "cargo build --manifest-path=src/tools/Cargo.toml"


if [[ "$FAILED" -gt 0 ]]; then
    echo "::error ::Build failed! Check logs." | tee -a $LOG_FILE
    exit 1
fi

echo "Build passed successfully!" | tee -a $LOG_FILE
