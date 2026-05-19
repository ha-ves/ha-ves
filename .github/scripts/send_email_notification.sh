#!/usr/bin/env bash
set -euo pipefail

# Output email section header
echo "## 📧 Email" >> "$GITHUB_STEP_SUMMARY"

if [ ! -f /tmp/email_report.html ]; then
  echo "⚠️ Email report was not generated; skipping email notification."
  echo "⚠️ Email skipped: report file was not generated." >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

if { [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ]; } && { [ -z "${OAUTH_CLIENT_ID:-}" ] || [ -z "${OAUTH_CLIENT_SECRET:-}" ] || [ -z "${OAUTH_REFRESH_TOKEN:-}" ]; }; then
  echo "⚠️ SMTP or OAuth credentials not configured. Skipping email notification."
  echo "To enable email notifications, set either SMTP credentials or OAuth credentials:" 
  echo "  Option A (SMTP):" 
  echo "    - SMTP_USERNAME (required)" 
  echo "    - SMTP_PASSWORD (required)" 
  echo "  Option B (OAuth/XOAUTH2):" 
  echo "    - OAUTH_CLIENT_ID" 
  echo "    - OAUTH_CLIENT_SECRET" 
  echo "    - OAUTH_REFRESH_TOKEN" 
  echo "    - (optional) OAUTH_TOKEN_URL (defaults to https://oauth2.googleapis.com/token)" 
  echo "  - SMTP_HOST (optional, defaults to smtp.gmail.com)" 
  echo "  - SMTP_PORT (optional, defaults to 587)" 
  echo "  - EMAIL_FROM (optional, defaults to SMTP_USERNAME)" 
  echo "  - EMAIL_TO (optional, defaults to SMTP_USERNAME)" 
  echo "⚠️ Email skipped: no valid credentials provided." >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

# Use the Python standard-library email sender (no extra packages required)
python3 .github/scripts/send_email.py
py_exit=$?
if [ $py_exit -eq 0 ]; then
  echo "✅ Email notification sent successfully."
  echo "✅ Email notification sent successfully." >> "$GITHUB_STEP_SUMMARY"
else
  echo "⚠️ Email notification failed (python exit $py_exit). Check SMTP settings and runner egress rules."
  echo "⚠️ Email notification failed. Check SMTP_HOST/SMTP_PORT and runner egress rules." >> "$GITHUB_STEP_SUMMARY"
fi
