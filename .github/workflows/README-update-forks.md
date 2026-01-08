# Update Forks Workflow

This GitHub Action automatically updates your forked repositories with upstream changes.

## Features

- **Automatic Updates**: Automatically merges upstream changes into forks that have no local modifications
- **Smart Detection**: Detects local changes and reports them for manual review
- **HTML Reports**: Generates detailed HTML reports with collapsible sections for each fork
- **Email Notifications**: Sends email reports via SMTP (optional)
- **Fallback Notifications**: Creates GitHub issues if email is not configured

## Triggers

The workflow runs:
- **Weekly**: Every Monday at 00:00 UTC
- **Manually**: Via workflow_dispatch in the Actions tab

## Configuration

### Required Secrets

None required for basic functionality! The workflow uses the default `GITHUB_TOKEN` automatically.

### Optional Secrets (for Email Notifications)

To enable email notifications via SMTP, configure these secrets in your repository settings:

| Secret | Description | Required |
|--------|-------------|----------|
| `SMTP_USERNAME` | SMTP username (usually your email) | Yes (for email) |
| `SMTP_PASSWORD` | SMTP password or app-specific password | Yes (for email) |
| `SMTP_HOST` | SMTP server hostname | No (defaults to `smtp.gmail.com`) |
| `SMTP_PORT` | SMTP server port | No (defaults to `587`) |
| `EMAIL_FROM` | Sender email address | No (defaults to `SMTP_USERNAME`) |
| `EMAIL_TO` | Recipient email address | No (defaults to `SMTP_USERNAME`) |

### Gmail Setup Example

If using Gmail, you need to create an App Password:

1. Enable 2-factor authentication on your Google account
2. Go to https://myaccount.google.com/apppasswords
3. Create a new app password for "Mail"
4. Use this app password as `SMTP_PASSWORD`
5. Set `SMTP_USERNAME` to your Gmail address

## How It Works

### Update Logic

For each fork:

1. **No Local Changes**: If the fork has no commits ahead of upstream:
   - Automatically merges upstream changes
   - Updates status: ✅ **Updated**

2. **Has Local Changes**: If the fork has commits not in upstream:
   - Reports the local commits
   - Provides recommendations for manual merge/rebase
   - Updates status: ⚠️ **Skipped**

3. **Already Up-to-Date**: If fork is current with upstream:
   - No action needed
   - Updates status: ℹ️ **No changes**

4. **Errors**: If clone/merge/push fails:
   - Reports the error
   - Updates status: ❌ **Failed**

### Report Structure

The HTML report includes:

- **Summary Section**: Total counts for updated, skipped, no-change, and failed forks
- **Fork Details**: Collapsible sections for each fork with:
  - Fork name and upstream repository
  - Update status
  - Commit details (for updates or local changes)
  - Manual update instructions (for skipped forks)
  - Error details (for failures)

## Notifications

### SMTP Email (Primary)

If SMTP credentials are configured, the workflow sends an HTML email with the full report.

### GitHub Issue (Fallback)

If SMTP is not configured or fails, the workflow creates a GitHub issue with:
- Summary statistics
- Link to the full workflow run
- Complete HTML report in a collapsible section

## Manual Triggering

To manually trigger the workflow:

1. Go to the **Actions** tab in your repository
2. Select **Update Forks** from the workflows list
3. Click **Run workflow**
4. Select the branch and click **Run workflow**

## Permissions

The workflow requires:
- `contents: write` - To push updates to forks
- `issues: write` - To create notification issues (fallback)

These permissions are automatically granted when using `GITHUB_TOKEN`.

## Limitations

- Maximum 100 forks processed per run (GitHub API pagination)
- Requires fast-forward merges (no conflict resolution)
- Only updates the default branch of each fork

## Troubleshooting

### Email not sending

1. Verify SMTP credentials are correct
2. Check if your SMTP provider requires app-specific passwords
3. Review workflow logs for SMTP connection errors
4. Check GitHub issue notifications as fallback

### Fork not updating

1. Check if fork has local commits (will be skipped)
2. Verify fork is not archived or disabled
3. Check workflow logs for specific error messages
4. Ensure `GITHUB_TOKEN` has necessary permissions

### Missing forks in report

1. Workflow processes forks owned by the authenticated user
2. Maximum 100 repositories per run
3. Only repositories marked as "fork" are included

## Security Considerations

- SMTP credentials are stored as encrypted GitHub secrets
- `GITHUB_TOKEN` is automatically scoped to the repository
- Email reports may contain repository names and commit messages
- Consider repository visibility when using email notifications

## Example Report

```html
Fork Update Report
Generated: 2026-01-08 12:00:00 UTC
Workflow Run: #123

Summary
Total Forks Processed: 5
Updated: 2
Skipped (local changes): 1
No changes: 1
Failed: 1

user/forked-repo
Upstream: original/repo
Status: Updated
[Upstream commits merged...]

user/another-fork
Upstream: someone/project  
Status: Skipped (local changes)
[Local commits found...]
Recommendation: Review local commits and decide...
```
