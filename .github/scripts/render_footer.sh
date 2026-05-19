#!/usr/bin/env bash
set -euo pipefail

# Read parameters from environment variables (set by caller)
TOTAL="${TOTAL:-0}"
UPDATED="${UPDATED:-0}"
SKIPPED="${SKIPPED:-0}"
NO_CHANGES="${NO_CHANGES:-0}"
FAILED="${FAILED:-0}"
REPO="${REPO:-unknown}"
RUN_ID="${RUN_ID:-unknown}"

TEMPLATE=".github/templates/email_footer.html"

bash .github/scripts/lib_template.sh "$TEMPLATE" \
  TOTAL="$TOTAL" \
  UPDATED="$UPDATED" \
  SKIPPED="$SKIPPED" \
  NO_CHANGES="$NO_CHANGES" \
  FAILED="$FAILED" \
  REPO="$REPO" \
  RUN_ID="$RUN_ID"

# Output summary to GITHUB_STEP_SUMMARY
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "## Summary" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "- **Total Forks:** $TOTAL" >> "$GITHUB_STEP_SUMMARY"
echo "- **Updated:** $UPDATED" >> "$GITHUB_STEP_SUMMARY"
echo "- **Skipped (local changes/conflicts):** $SKIPPED" >> "$GITHUB_STEP_SUMMARY"
echo "- **Already up to date:** $NO_CHANGES" >> "$GITHUB_STEP_SUMMARY"
echo "- **Failed:** $FAILED" >> "$GITHUB_STEP_SUMMARY"
