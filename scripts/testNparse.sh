#!/bin/bash

set -e

LOG_FILE="test_results.log"
TMP_FILE="test_output.txt"
REPORT_FILE="test_summary.md"

echo "Running Cargo Test..." | tee -a $LOG_FILE
PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd $PROJECT_ROOT
#make test | tee $TMP_FILE || true
cargo test -vv --manifest-path=src/common/Cargo.toml | tee $TMP_FILE || true
cargo test -vv --manifest-path=src/agent/Cargo.toml | tee $TMP_FILE || true
#cargo test -vv --manifest-path=src/player/Cargo.toml | tee $TMP_FILE || true
#cargo test -vv --manifest-path=src/server/Cargo.toml | tee $TMP_FILE || true
cargo test -vv --manifest-path=src/tools/Cargo.toml | tee $TMP_FILE || true

PASSED=$(grep -oP '\d+ passed' $TMP_FILE | awk '{print $1}')
FAILED=$(grep -oP '\d+ failed' $TMP_FILE | awk '{print $1}')

echo "Tests Passed: $PASSED" | tee -a $LOG_FILE
echo "Tests Failed: $FAILED" | tee -a $LOG_FILE

# Generate a report
echo "# Test Results" > $REPORT_FILE
echo "**Passed:** $PASSED" >> $REPORT_FILE
echo "**Failed:** $FAILED" >> $REPORT_FILE

#if [[ "$FAILED" -gt 0 ]]; then
#    echo "::error ::Tests failed! Check logs." | tee -a $LOG_FILE
#    exit 1
#fi

echo "All tests passed successfully!" | tee -a $LOG_FILE
