#!/usr/bin/env python3
"""Interactive helper to obtain a Google OAuth refresh token for XOAUTH2 (InstalledAppFlow).

Place a `client_secrets.json` (OAuth client, type 'Desktop' / 'Other') next to this script and run it.
It will open a browser and print environment variable exports for GitHub Actions or local usage.

Scopes: https://mail.google.com/ (full Gmail SMTP/IMAP/POP access needed for SMTP XOAUTH2)
"""
import argparse
import json
import os
import sys

try:
    from google_auth_oauthlib.flow import InstalledAppFlow
except Exception:
    print("google-auth-oauthlib is required for interactive token acquisition. Install with: pip install google-auth-oauthlib")
    sys.exit(2)


def parse_args():
    p = argparse.ArgumentParser(description="Interactive helper to obtain a Google OAuth refresh token for XOAUTH2")
    p.add_argument("--secrets-file", "-s", default="client_secrets.json", help="Path to OAuth client_secrets.json")
    p.add_argument("--output-file", "-o", default=".github/scripts/.oauth_credentials.json", help="Path to write the extracted credentials (DO NOT COMMIT)")
    p.add_argument("--scopes", help="Comma-separated OAuth scopes", default="https://mail.google.com/")
    p.add_argument("--port", type=int, default=0, help="Local server port (0 = auto)")
    p.add_argument("--no-write", action="store_true", help="Do not write the output file, only print exports")
    p.add_argument("--no-browser", action="store_true", help="Do not open a browser; use console copy/paste flow instead")
    return p.parse_args()


def main():
    args = parse_args()
    secrets_file = args.secrets_file
    out_file = args.output_file
    scopes = [s.strip() for s in args.scopes.split(",") if s.strip()]

    if not os.path.exists(secrets_file):
        print(f"{secrets_file} not found. Create an OAuth client in Google Cloud Console and download the JSON as {secrets_file}.")
        sys.exit(1)

    with open(secrets_file, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    client_info = cfg.get("installed") or cfg.get("web")
    if not client_info:
        print("client_secrets.json does not contain 'installed' or 'web' keys. Ensure you downloaded the OAuth client JSON.")
        sys.exit(1)

    flow = InstalledAppFlow.from_client_secrets_file(secrets_file, scopes)
    try:
        if args.no_browser:
            # Console flow: prints URL and accepts pasted code
            creds = flow.run_console()
        else:
            # Local server flow: opens browser and waits for callback
            creds = flow.run_local_server(port=args.port)
    except KeyboardInterrupt:
        print("\nInterrupted by user (Ctrl+C). Use --no-browser to run a copy/paste flow instead.")
        sys.exit(130)

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

    out = {
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
    }

    if not args.no_write:
        try:
            os.makedirs(os.path.dirname(out_file), exist_ok=True)
            with open(out_file, "w", encoding="utf-8") as wf:
                json.dump(out, wf)
            print(f"\nWrote {out_file} (DO NOT COMMIT this file)")
        except Exception as e:
            print(f"Warning: failed to write {out_file}: {e}")


if __name__ == "__main__":
    main()
