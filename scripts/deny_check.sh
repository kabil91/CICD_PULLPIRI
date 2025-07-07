#!/bin/bash
set -euo pipefail

LOG_FILE="deny_results.log"
TMP_FILE="deny_output.txt"
REPORT_FILE="deny_summary.md"

rm -f "$LOG_FILE" "$TMP_FILE" "$REPORT_FILE"

echo "🔍 Running Cargo Deny checks..." | tee -a "$LOG_FILE"

PROJECT_ROOT=${GITHUB_WORKSPACE:-$(pwd)}
cd "$PROJECT_ROOT"

FAILED_TOTAL=0
PASSED_TOTAL=0

APISERVER_MANIFEST="src/server/apiserver/Cargo.toml"

run_deny() {
  local manifest="$1"
  local label="$2"

  echo -e "\n🚨 Checking $label ($manifest)..." | tee -a "$LOG_FILE"

  if cargo deny --manifest-path="$manifest" check 2>&1 | tee "$TMP_FILE"; then
    echo "✅ Deny check for $label passed clean." | tee -a "$LOG_FILE"
    echo "✅ deny check for $label: PASSED" >> "$REPORT_FILE"
    (( PASSED_TOTAL++ ))
  else
    echo "::error ::Deny check for $label failed! Issues found." | tee -a "$LOG_FILE"
    grep -E "error:|warning:" "$TMP_FILE" || true | tee -a "$LOG_FILE"
    echo "❌ deny check for $label: FAILED" >> "$REPORT_FILE"
    (( FAILED_TOTAL++ ))
  fi
}


if [[ -f "$APISERVER_MANIFEST" ]]; then
  run_deny "$APISERVER_MANIFEST" "apiserver"
else
  echo "::warning ::$APISERVER_MANIFEST not found, skipping..." | tee -a "$LOG_FILE"
fi

echo -e "\n📄 Summary Report:" | tee -a "$LOG_FILE"
cat "$REPORT_FILE" | tee -a "$LOG_FILE"

echo -e "\n🔢 Total Passed: $PASSED_TOTAL" | tee -a "$LOG_FILE"
echo "🔢 Total Failed: $FAILED_TOTAL" | tee -a "$LOG_FILE"

if [[ "$FAILED_TOTAL" -gt 0 ]]; then
  echo "::error ::One or more cargo-deny checks failed."
  exit 1
else
  echo "✅ All cargo-deny checks passed successfully!"
  exit 0
fi