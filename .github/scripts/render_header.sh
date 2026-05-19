#!/usr/bin/env bash
set -euo pipefail

# Calculate from system call
EPOCH=$(date -u +%s)
DATE_TEXT=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

TEMPLATE=".github/templates/email_header.html"

bash .github/scripts/lib_template.sh "$TEMPLATE" \
  EPOCH="$EPOCH" \
  DATE_TEXT="$DATE_TEXT"

# Output header to GITHUB_STEP_SUMMARY
echo "# Fork Update Report" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "**Generated:** $DATE_TEXT" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
