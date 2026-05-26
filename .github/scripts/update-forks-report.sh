#!/usr/bin/env bash
set -euo pipefail


html_escape() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&#39;/g'
}

append_html() {
  printf '%s\n' "$@" >> /tmp/email_report.html
}

updated_count=0
skipped_count=0
failed_count=0
no_changes_count=0

if [ -f /tmp/forks.txt ]; then
  fork_count=$(wc -l < /tmp/forks.txt | tr -d '[:space:]')
else
  fork_count=0
fi
if [ "$fork_count" -eq 0 ]; then
  echo "updated_count=0" >> "$GITHUB_OUTPUT"
  echo "skipped_count=0" >> "$GITHUB_OUTPUT"
  echo "failed_count=0" >> "$GITHUB_OUTPUT"
  echo "no_changes_count=0" >> "$GITHUB_OUTPUT"
  echo "total_count=0" >> "$GITHUB_OUTPUT"
  exit 0
fi

while IFS=$'\t' read -r fork_name parent_owner parent_repo default_branch; do
  echo ""
  echo "Processing fork: $fork_name ($default_branch)"

  if [ -n "${SKIP_REPOS:-}" ]; then
    skip_this=false
    OLDIFS="$IFS"
    IFS=', '
    for skip_entry in $SKIP_REPOS; do
      [ -z "$skip_entry" ] && continue
      if [ "$skip_entry" = "$fork_name" ]; then
        skip_this=true
        break
      fi
    done
    IFS="$OLDIFS"
    if [ "$skip_this" = "true" ]; then
      echo "  ⏭ Skipping $fork_name (in SKIP_REPOS)"
      fork_name_esc=$(html_escape "$fork_name")
      bash .github/scripts/lib_template.sh ".github/templates/item_warning.html" \
        FORK_LINK="https://github.com/$fork_name" \
        FORK_NAME_ESC="$fork_name_esc" \
        ICON="⏭" \
        STATUS_TEXT="Skipped" \
        DETAIL_TEXT="Skipped (excluded via SKIP_REPOS)" \
        EXTRA=""
      skipped_count=$((skipped_count + 1))
      continue
    fi
  fi

  parent_name="$parent_owner/$parent_repo"
  set +e
  parent_head_sha=$(gh api "repos/$parent_owner/$parent_repo/commits/$default_branch" --jq '.sha' 2>&1)
  parent_sha_exit=$?
  set -e
  if [ $parent_sha_exit -ne 0 ]; then
    error_msg=$(echo "$parent_head_sha" | head -1)
    echo "::error::Failed to resolve upstream commit for $fork_name: $error_msg"

    fork_name_esc=$(html_escape "$fork_name")
    parent_name_esc=$(html_escape "$parent_name")
    error_msg_esc=$(html_escape "$error_msg")
    bash .github/scripts/lib_template.sh ".github/templates/item_error.html" \
      FORK_LINK="https://github.com/$fork_name" \
      FORK_NAME_ESC="$fork_name_esc" \
      DETAIL_TEXT="Failed to resolve upstream commit" \
      UPSTREAM_LINK="https://github.com/$parent_name" \
      UPSTREAM_ESC="$parent_name_esc" \
      ERROR_MSG="$error_msg_esc" \
      COMPARE_LINK="https://github.com/$fork_name"
    failed_count=$((failed_count + 1))
    continue
  fi

  set +e
  fork_head_sha=$(gh api "repos/$fork_name/commits/$default_branch" --jq '.sha' 2>&1)
  fork_sha_exit=$?
  set -e
  if [ $fork_sha_exit -ne 0 ]; then
    error_msg=$(echo "$fork_head_sha" | head -1)
    echo "::error::Failed to resolve fork commit for $fork_name: $error_msg"

    fork_name_esc=$(html_escape "$fork_name")
    parent_name_esc=$(html_escape "$parent_name")
    error_msg_esc=$(html_escape "$error_msg")
    bash .github/scripts/lib_template.sh ".github/templates/item_error.html" \
      FORK_LINK="https://github.com/$fork_name" \
      FORK_NAME_ESC="$fork_name_esc" \
      DETAIL_TEXT="Failed to resolve fork commit" \
      UPSTREAM_LINK="https://github.com/$parent_name" \
      UPSTREAM_ESC="$parent_name_esc" \
      ERROR_MSG="$error_msg_esc" \
      COMPARE_LINK="https://github.com/$fork_name"
    failed_count=$((failed_count + 1))
    continue
  fi

  compare_link="https://github.com/$fork_name/compare/${parent_head_sha}...${fork_head_sha}"
  set +e
  compare_result=$(gh api "repos/$fork_name/compare/${parent_head_sha}...${fork_head_sha}" 2>&1)
  compare_exit=$?
  set -e
  if [ $compare_exit -ne 0 ]; then
    error_msg=$(echo "$compare_result" | head -1)
    echo "::error::Failed to compare $fork_name: $error_msg"

    fork_name_esc=$(html_escape "$fork_name")
    parent_name_esc=$(html_escape "$parent_name")
    error_msg_esc=$(html_escape "$error_msg")
    bash .github/scripts/lib_template.sh ".github/templates/item_error.html" \
      FORK_LINK="https://github.com/$fork_name" \
      FORK_NAME_ESC="$fork_name_esc" \
      DETAIL_TEXT="Failed to compare with upstream" \
      UPSTREAM_LINK="https://github.com/$parent_name" \
      UPSTREAM_ESC="$parent_name_esc" \
      ERROR_MSG="$error_msg_esc" \
      COMPARE_LINK="$compare_link"
    failed_count=$((failed_count + 1))
    continue
  fi

  ahead_by=$(echo "$compare_result" | jq -r '.ahead_by // 0')
  behind_by=$(echo "$compare_result" | jq -r '.behind_by // 0')

  echo "  Ahead: $ahead_by, Behind: $behind_by"

  if [ "$ahead_by" -gt 0 ]; then
    echo "::warning::$fork_name has $ahead_by commit(s) ahead of upstream. Manual intervention required."
    fork_name_esc=$(html_escape "$fork_name")
    parent_name_esc=$(html_escape "$parent_name")
    bash .github/scripts/lib_template.sh ".github/templates/item_warning.html" \
      FORK_LINK="https://github.com/$fork_name" \
      FORK_NAME_ESC="$fork_name_esc" \
      ICON="⚠️" \
      STATUS_TEXT="Skipped" \
      DETAIL_TEXT="Skipped (has local commits)" \
      EXTRA="<div class=\"detail\"><strong>Upstream:</strong> <a href=\"https://github.com/$parent_name\">$parent_name_esc</a></div><div class=\"detail\"><strong>Ahead by:</strong> $ahead_by commit(s)</div><div class=\"detail\"><strong>Behind by:</strong> $behind_by commit(s)</div><div class=\"detail\"><strong>Action Required:</strong> This fork has local commits. You need to manually merge or rebase.</div><div class=\"detail\"><a href=\"$compare_link\">Compare</a></div>" \
      COMPARE_LINK="$compare_link"
    skipped_count=$((skipped_count + 1))
  elif [ "$behind_by" -eq 0 ]; then
    echo "  ✓ Already up to date"
    fork_name_esc=$(html_escape "$fork_name")
    parent_name_esc=$(html_escape "$parent_name")
    bash .github/scripts/lib_template.sh ".github/templates/item_info.html" \
      FORK_LINK="https://github.com/$fork_name" \
      FORK_NAME_ESC="$fork_name_esc" \
      UPSTREAM_LINK="https://github.com/$parent_name" \
      UPSTREAM_ESC="$parent_name_esc" \
      COMPARE_LINK="$compare_link"
    no_changes_count=$((no_changes_count + 1))
  else
    echo "  Attempting to sync fork (behind by $behind_by commits)..."
    set +e
    sync_output=$(gh repo sync "$fork_name" --branch "$default_branch" 2>&1)
    sync_exit=$?
    set -e

    if [ $sync_exit -eq 0 ]; then
      echo "  ✓ Successfully synced fork"
      fork_name_esc=$(html_escape "$fork_name")
      parent_name_esc=$(html_escape "$parent_name")
      bash .github/scripts/lib_template.sh ".github/templates/item_success.html" \
        FORK_LINK="https://github.com/$fork_name" \
        FORK_NAME_ESC="$fork_name_esc" \
        UPSTREAM_LINK="https://github.com/$parent_name" \
        UPSTREAM_ESC="$parent_name_esc" \
        COMMITS="$behind_by" \
        COMPARE_LINK="$compare_link"
      updated_count=$((updated_count + 1))
    else
      if echo "$sync_output" | grep -qi "conflict"; then
        echo "::warning::$fork_name cannot be auto-synced: merge conflict"
        fork_name_esc=$(html_escape "$fork_name")
        parent_name_esc=$(html_escape "$parent_name")
        bash .github/scripts/lib_template.sh ".github/templates/item_warning.html" \
          FORK_LINK="https://github.com/$fork_name" \
          FORK_NAME_ESC="$fork_name_esc" \
          ICON="⚠️" \
          STATUS_TEXT="Merge conflict" \
          DETAIL_TEXT="Merge conflict" \
          EXTRA="<div class=\"detail\"><strong>Upstream:</strong> <a href=\"https://github.com/$parent_name\">$parent_name_esc</a></div><div class=\"detail\"><strong>Action Required:</strong> Manual merge required due to conflicts.</div>"
        skipped_count=$((skipped_count + 1))
      else
        message=$(echo "$sync_output" | head -1)
        echo "::error::Failed to sync $fork_name: $message"
        fork_name_esc=$(html_escape "$fork_name")
        parent_name_esc=$(html_escape "$parent_name")
        message_esc=$(html_escape "$message")
        bash .github/scripts/lib_template.sh ".github/templates/item_error.html" \
          FORK_LINK="https://github.com/$fork_name" \
          FORK_NAME_ESC="$fork_name_esc" \
          DETAIL_TEXT="Failed" \
          UPSTREAM_LINK="https://github.com/$parent_name" \
          UPSTREAM_ESC="$parent_name_esc" \
          ERROR_MSG="$message_esc" \
          COMPARE_LINK="$compare_link"
        failed_count=$((failed_count + 1))
      fi
    fi
  fi

done < /tmp/forks.txt

echo "updated_count=$updated_count" >> "$GITHUB_OUTPUT"
echo "skipped_count=$skipped_count" >> "$GITHUB_OUTPUT"
echo "failed_count=$failed_count" >> "$GITHUB_OUTPUT"
echo "no_changes_count=$no_changes_count" >> "$GITHUB_OUTPUT"
echo "total_count=$fork_count" >> "$GITHUB_OUTPUT"
