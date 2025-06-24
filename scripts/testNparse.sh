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

# Declare manifest paths
COMMON_MANIFEST="src/common/Cargo.toml"
AGENT_MANIFEST="src/agent/Cargo.toml"
TOOLS_MANIFEST="src/tools/Cargo.toml"
APISERVER_MANIFEST="src/server/apiserver/Cargo.toml"
FILTERGATEWAY_MANIFEST="src/payer/filtergateway/Cargo.toml"
# Function to run and parse test output
run_tests() {
  local manifest="$1"
  local label="$2"

  echo "Testing $label ($manifest)" | tee -a "$LOG_FILE"

  if cargo test -vv --manifest-path="$manifest" -- --test-threads=1 | tee "$TMP_FILE"; then
    echo "✅ Tests passed for $label"
  else
    echo "::error ::Tests failed for $label! Check logs." | tee -a "$LOG_FILE"
  fi

  local passed
  local failed

  passed=$(grep -oP '\d+ passed' "$TMP_FILE" | awk '{sum += $1} END {print sum}')
  failed=$(grep -oP '\d+ failed' "$TMP_FILE" | awk '{sum += $1} END {print sum}')

  PASSED_TOTAL=$((PASSED_TOTAL + passed))
  FAILED_TOTAL=$((FAILED_TOTAL + failed))
}

# Run common tests
if [[ -f "$COMMON_MANIFEST" ]]; then
  run_tests "$COMMON_MANIFEST" "common"
else
  echo "::warning ::$COMMON_MANIFEST not found, skipping..."
fi

# Start filtergateway (required by apiserver)
echo "🚀 Starting filtergateway component for apiserver tests..."
cargo run --manifest-path="$FILTERGATEWAY_MANIFEST" &

TOOLS_PID=$!
sleep 10  # Optional: wait for the service to be ready

# Run apiserver tests
if [[ -f "$APISERVER_MANIFEST" ]]; then
  run_tests "$APISERVER_MANIFEST" "apiserver"
else
  echo "::warning ::$APISERVER_MANIFEST not found, skipping..."
fi

# Stop filtergateway process
echo "🛑 Stopping filtergateway component after apiserver tests..."
kill "$TOOLS_PID"
wait "$TOOLS_PID" 2>/dev/null || true

# Run tools tests
if [[ -f "$TOOLS_MANIFEST" ]]; then
  run_tests "$TOOLS_MANIFEST" "tools"
else
  echo "::warning ::$TOOLS_MANIFEST not found, skipping..."
fi

# Run agent tests
if [[ -f "$AGENT_MANIFEST" ]]; then
  run_tests "$AGENT_MANIFEST" "tools"
else
  echo "::warning ::$AGENT_MANIFEST not found, skipping..."
fi

# Generate a test report
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
