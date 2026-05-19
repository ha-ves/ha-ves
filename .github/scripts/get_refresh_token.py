#!/usr/bin/env python3
"""Interactive helper to obtain a Google OAuth refresh token for XOAUTH2 (InstalledAppFlow).

Place a `client_secrets.json` (OAuth client, type 'Desktop' / 'Other') next to this script and run it.
It will open a browser and print environment variable exports for GitHub Actions or local usage.

Scopes: https://mail.google.com/ (full Gmail SMTP/IMAP/POP access needed for SMTP XOAUTH2)
"""
import json
import os
import sys

try:
    from google_auth_oauthlib.flow import InstalledAppFlow
except Exception:
    print("google-auth-oauthlib is required. Install with: pip install google-auth-oauthlib")
    sys.exit(2)

SCOPES = ["https://mail.google.com/"]

SECRETS_FILE = "client_secrets.json"


def main():
    if not os.path.exists(SECRETS_FILE):
        print(f"{SECRETS_FILE} not found. Create an OAuth client in Google Cloud Console and download the JSON as {SECRETS_FILE}.")
        sys.exit(1)

    with open(SECRETS_FILE, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    # Determine client info location (installed or web)
    client_info = cfg.get("installed") or cfg.get("web")
    if not client_info:
        print("client_secrets.json does not contain 'installed' or 'web' keys. Ensure you downloaded the OAuth client JSON.")
        sys.exit(1)

    flow = InstalledAppFlow.from_client_secrets_file(SECRETS_FILE, SCOPES)
    creds = flow.run_local_server(port=0)

    client_id = client_info.get("client_id")
    client_secret = client_info.get("client_secret")
    refresh_token = creds.refresh_token

    print("\n=== OAuth credentials ===")
    print(f"CLIENT_ID={client_id}")
    print(f"CLIENT_SECRET={client_secret}")
    print(f"REFRESH_TOKEN={refresh_token}")
    print("\nExport commands (example):")
    print(f"export OAUTH_CLIENT_ID=\"{client_id}\"")
    print(f"export OAUTH_CLIENT_SECRET=\"{client_secret}\"")
    print(f"export OAUTH_REFRESH_TOKEN=\"{refresh_token}\"")

    # Optionally write to a local file for convenience (don't commit!)
    out = {
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
    }
    try:
        with open(".github/scripts/.oauth_credentials.json", "w", encoding="utf-8") as wf:
            json.dump(out, wf)
        print("\nWrote .github/scripts/.oauth_credentials.json (DO NOT COMMIT this file)")
    except Exception:
        pass


if __name__ == "__main__":
    main()
