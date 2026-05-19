#!/usr/bin/env bash
set -euo pipefail

# lib_template.sh: callable helper that renders a template and appends to /tmp/email_report.html
# Usage: lib_template.sh TEMPLATE_PATH KEY=VALUE KEY=VALUE ...

template="$1"; shift
tmpfile=$(mktemp)
cp "$template" "$tmpfile"
for kv in "$@"; do
  key=${kv%%=*}
  val=${kv#*=}
  # escape forward slashes and ampersands for sed
  esc=$(printf '%s' "$val" | sed -e 's/[\/&]/\\&/g')
  sed -i "s/%%${key}%%/${esc}/g" "$tmpfile"
done
cat "$tmpfile" >> /tmp/email_report.html
rm -f "$tmpfile"
