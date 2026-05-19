#!/usr/bin/env bash
set -euo pipefail

repo="${REPO:-${GITHUB_REPOSITORY:-}}"
if [ -z "$repo" ]; then
  echo "::error::REPO or GITHUB_REPOSITORY is required to gather forks"
  exit 1
fi

parent_owner="${repo%%/*}"
parent_repo="${repo#*/}"

: > /tmp/forks.txt

gh api --paginate "repos/$repo/forks?per_page=100" --jq '.[] | [.full_name, .default_branch] | @tsv' |
while IFS=$'\t' read -r fork_name default_branch; do
  [ -z "$fork_name" ] && continue
  printf '%s\t%s\t%s\t%s\n' "$fork_name" "$parent_owner" "$parent_repo" "${default_branch:-main}"
done > /tmp/forks.txt

fork_count=$(wc -l < /tmp/forks.txt | tr -d '[:space:]')
printf '%s\n' "$fork_count" > /tmp/fork_count
echo "Collected $fork_count fork(s) for $repo"