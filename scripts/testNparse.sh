#!/bin/bash
set -euo pipefail

LOG_FILE="test_results.log"
TMP_FILE="test_output.txt"
REPORT_FILE="test_summary.md"

rm -f "$LOG_FILE" "$TMP_FILE" "$REPORT_FILE"

echo "Running Cargo Tests..." | tee -a "$LOG_FILE"

PROJECT_ROOT=${GITHUB_WORKSPACE:-$(pwd)}
cd "$PROJECT_ROOT"

FAILED_TOTAL=0
PASSED_TOTAL=0

# Define your manifest paths
MANIFESTS=(
  src/common/Cargo.toml
  src/agent/Cargo.toml
  src/tools/Cargo.toml
)

for manifest in "${MANIFESTS[@]}"; do
  if [[ ! -f "$manifest" ]]; then
    echo "::warning ::$manifest not found, skipping..." | tee -a "$LOG_FILE"
    continue
  fi

  echo "Testing $manifest" | tee -a "$LOG_FILE"

  if cargo test --manifest-path="$manifest" -- --test-threads=1 -vv | tee "$TMP_FILE"; then
    echo "✅ Tests passed for $manifest"
  else
    echo "::error ::Tests failed for $manifest! Check logs." | tee -a "$LOG_FILE"
  fi

  PASSED=$(grep -oP '\d+ passed' "$TMP_FILE" | awk '{sum += $1} END {print sum}')
  FAILED=$(grep -oP '\d+ failed' "$TMP_FILE" | awk '{sum += $1} END {print sum}')

  PASSED_TOTAL=$((PASSED_TOTAL + PASSED))
  FAILED_TOTAL=$((FAILED_TOTAL + FAILED))
done

# Generate a report
echo "# Test Results" > "$REPORT_FILE"
echo "**Passed:** $PASSED_TOTAL" >> "$REPORT_FILE"
echo "**Failed:** $FAILED_TOTAL" >> "$REPORT_FILE"

echo "Tests Passed: $PASSED_TOTAL" | tee -a "$LOG_FILE"
echo "Tests Failed: $FAILED_TOTAL" | tee -a "$LOG_FILE"

if [[ "$FAILED_TOTAL" -gt 0 ]]; then
  echo "::error ::Some tests failed!" | tee -a "$LOG_FILE"
  exit 1
fi

echo "✅ All tests passed successfully!" | tee -a "$LOG_FILE"
