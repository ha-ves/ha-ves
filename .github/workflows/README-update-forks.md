# Update Forks Workflow

This GitHub Action automatically updates your forked repositories with upstream changes using GitHub's native API.

## Features

- **API-Based Updates**: Uses GitHub's merge-upstream API (no cloning, no storage waste)
- **Smart Detection**: Detects local changes and reports them for manual review
- **Job Summary Reports**: Native GitHub markdown summaries with status for each fork
- **Self-Hosted Runner Support**: Prefers self-hosted runner with automatic fallback to GitHub-hosted

## Triggers

The workflow runs:
- **Weekly**: Every Monday at 00:00 UTC
- **Manually**: Via workflow_dispatch in the Actions tab

## Configuration

### Required Secrets

- **`METRICS_TOKEN`**: GitHub token with `repo` and `read:org` scopes (for runner fallback check)
  - Same token used by the metrics workflow

### How It Works

The workflow uses GitHub's REST API to:

1. **Fetch forks**: Queries `/user/repos` for forked repositories
2. **Compare commits**: Uses `/repos/{owner}/{repo}/compare` to check ahead/behind status
3. **Merge upstream**: Calls `/repos/{owner}/{repo}/merge-upstream` to sync forks

No cloning needed - everything is done via API calls!

### Update Logic

For each fork:

1. **Has Local Commits (ahead)**: 
   - Reports with `::warning::` annotation
   - Shows in job summary with ⚠️ warning icon
   - Provides commit count and recommendation
   - Status: **Skipped**

2. **Behind Upstream**: 
   - Automatically syncs using merge-upstream API
   - Fast-forward or merge based on GitHub's decision
   - Reports merge type (fast-forward, merge, etc.)
   - Status: **Updated** ✅

3. **Already Up-to-Date**: 
   - No action needed
   - Reports in summary
   - Status: **Up to date** ✅

4. **Merge Conflict (409)**:
   - Cannot auto-merge
   - Reports conflict with error message
   - Status: **Skipped** ⚠️

5. **Other Errors**:
   - API errors, permissions, etc.
   - Reports with `::error::` annotation
   - Shows HTTP status and message
   - Status: **Failed** ❌

### Job Summary

The workflow creates a GitHub Actions job summary with:

- **Timestamp**: When the report was generated
- **Fork Status**: Section for each fork with icon and details
  - ✅ Successfully updated
  - ⚠️ Skipped (local changes or conflicts)  
  - ❌ Failed (API errors)
- **Summary Statistics**: Total counts by status

Access the job summary from the Actions run page.

## Manual Triggering

To manually trigger the workflow:

1. Go to the **Actions** tab in your repository
2. Select **Update Forks** from the workflows list
3. Click **Run workflow**
4. Select the branch and click **Run workflow**

## Permissions

The workflow requires:
- `contents: write` - To push updates to forks via API

These permissions are automatically granted when using `GITHUB_TOKEN`.

## Limitations

- Maximum 100 forks processed per run (GitHub API pagination)
- Only updates the default branch of each fork
- Requires GitHub's merge-upstream API (available on all forks)

## Troubleshooting

### Fork not updating

1. Check job summary for specific error messages
2. Review workflow annotations (warnings/errors)
3. Check if fork has local commits (will be skipped)
4. Verify `GITHUB_TOKEN` has necessary permissions
5. Ensure fork is not archived or disabled

### Missing forks in report

1. Workflow processes forks owned by the authenticated user
2. Maximum 100 repositories per run (API limit)
3. Only repositories marked as "fork" are included

### Runner fallback not working

1. Verify `METRICS_TOKEN` secret is configured
2. Token needs `read:org` permission for runner API
3. Check workflow logs for runner selection details

## Advantages Over Git Cloning

- **No Storage Usage**: Doesn't clone repositories locally
- **Faster**: API calls are much quicker than git operations
- **Simpler**: No need to manage git credentials or cleanup
- **GitHub Native**: Uses official merge-upstream endpoint
- **Safer**: No token exposure in git URLs

## Example Job Summary

```markdown
# Fork Update Report

**Generated:** 2026-01-08 12:00:00 UTC

---

## ✅ user/forked-repo

**Status:** Successfully updated
**Upstream:** original/repo
**Commits synced:** 5
**Merge type:** fast-forward

## ⚠️ user/another-fork

**Status:** Skipped (has local commits)
**Upstream:** someone/project  
**Ahead by:** 3 commit(s)
**Behind by:** 2 commit(s)

**Action Required:** This fork has local commits. You need to manually merge or rebase.

---

## Summary

- **Total Forks:** 5
- **Updated:** 2
- **Skipped (local changes/conflicts):** 1
- **Already up to date:** 1
- **Failed:** 1
```

## Security Considerations

- `GITHUB_TOKEN` is automatically scoped to the repository
- All API calls use authenticated endpoints
- No credentials stored in git history
- Job summaries are only visible to repository collaborators
