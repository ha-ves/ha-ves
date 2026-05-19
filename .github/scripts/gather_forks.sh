#!/usr/bin/env bash
set -euo pipefail

repo="${REPO:-${GITHUB_REPOSITORY:-}}"
if [ -z "$repo" ]; then
  echo "::error::REPO or GITHUB_REPOSITORY is required to gather forks"
  exit 1
fi

account_owner="${repo%%/*}"

account_type=$(gh api "users/$account_owner" --jq '.type // "User"')
if [ "$account_type" = "Organization" ]; then
  repos_endpoint="orgs/$account_owner/repos?type=forks&per_page=100"
else
  repos_endpoint="users/$account_owner/repos?type=forks&per_page=100"
fi

echo "Gathering account forks for $account_owner ($account_type)"
echo "Querying: $repos_endpoint"

: > /tmp/forks.txt

account_fork_count=0

gh api --paginate "$repos_endpoint" --jq '.[] | select(.fork == true) | [.full_name, .default_branch] | @tsv' |
while IFS=$'\t' read -r fork_full_name list_default_branch; do
  [ -z "$fork_full_name" ] && continue

  repo_detail=$(gh api "repos/$fork_full_name" --jq '[.full_name, .parent.owner.login, .parent.name, .default_branch] | @tsv')
  IFS=$'\t' read -r full_name parent_owner parent_repo detail_default_branch <<< "$repo_detail"
  default_branch="${detail_default_branch:-${list_default_branch:-main}}"

  printf '%s\t%s\t%s\t%s\n' "$full_name" "$parent_owner" "$parent_repo" "$default_branch"
  account_fork_count=$((account_fork_count + 1))
done > /tmp/forks.txt

fork_count=$(wc -l < /tmp/forks.txt | tr -d '[:space:]')
printf '%s\n' "$fork_count" > /tmp/fork_count

if [ "$fork_count" -eq 0 ]; then
  echo "::warning::No forked repositories were found for account $account_owner"
fi

echo "Collected $fork_count forked repository(s) for account $account_owner"