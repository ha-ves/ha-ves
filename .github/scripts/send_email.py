#!/usr/bin/env python3
"""Send an HTML email using only the Python standard library.

Reads the HTML body from /tmp/email_report.html by default and sends via SMTP.
Environment variables used:
  SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, EMAIL_FROM, EMAIL_TO
  OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET, OAUTH_REFRESH_TOKEN, OAUTH_USER_EMAIL, OAUTH_TOKEN_URL

Exits with 0 on success, non-zero on failure.
"""
import os
import sys
import smtplib
import ssl
import json
import base64
from email.message import EmailMessage

# Optional google-auth usage for OAuth2 token refresh
try:
    from google.oauth2.credentials import Credentials as GoogleCredentials
    from google.auth.transport.requests import Request as GoogleRequest
    _HAS_GOOGLE_AUTH = True
except Exception:
    _HAS_GOOGLE_AUTH = False


def main():
    smtp_host = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    # Credentials: either SMTP username/password, or OAuth client credentials + refresh token
    smtp_user = os.environ.get("SMTP_USERNAME")
    smtp_pass = os.environ.get("SMTP_PASSWORD")

    # OAuth credential environment variables (accept multiple common names)
    client_id = os.environ.get("OAUTH_CLIENT_ID") or os.environ.get("CLIENT_ID")
    client_secret = os.environ.get("OAUTH_CLIENT_SECRET") or os.environ.get("CLIENT_SECRET")
    refresh_token = os.environ.get("OAUTH_REFRESH_TOKEN") or os.environ.get("REFRESH_TOKEN")
    oauth_user = os.environ.get("OAUTH_USER_EMAIL")
    token_url = os.environ.get("OAUTH_TOKEN_URL") or "https://oauth2.googleapis.com/token"
    email_from = os.environ.get("EMAIL_FROM") or smtp_user
    email_to = os.environ.get("EMAIL_TO") or smtp_user

    use_xoauth2 = bool(client_id and client_secret and refresh_token)

    if use_xoauth2 and not _HAS_GOOGLE_AUTH:
        print("⚠️ google-auth is required for OAuth token refresh. Install with 'pip install -r requirements.txt'.")
        return 2

    if use_xoauth2 and not oauth_user:
        print("⚠️ OAUTH_USER_EMAIL is required when using OAuth. Set this to the email address authorized for the refresh token.")
        return 2

    if not use_xoauth2 and (not smtp_user or not smtp_pass):
        print("⚠️ SMTP credentials not configured. Skipping email notification.")
        print("Set SMTP_USERNAME and SMTP_PASSWORD, or configure OAUTH_CLIENT_ID / OAUTH_CLIENT_SECRET / OAUTH_REFRESH_TOKEN / OAUTH_USER_EMAIL to enable XOAUTH2.")
        return 0

    if not os.path.exists("/tmp/email_report.html"):
        print("⚠️ /tmp/email_report.html not found. Nothing to send.")
        return 0

    with open("/tmp/email_report.html", "r", encoding="utf-8") as f:
        html = f.read()

    subject = os.environ.get("EMAIL_SUBJECT") or "Fork Update Report"

    msg = EmailMessage()
    msg["From"] = email_from
    msg["To"] = email_to
    msg["Subject"] = subject
    msg.set_content("This is an HTML email. Please view in an HTML-capable client.")
    msg.add_alternative(html, subtype="html")

    # support multiple recipients comma/space separated
    recipients = [r.strip() for r in email_to.replace(';', ',').split(',') if r.strip()]

    try:
        access_token = None
        if use_xoauth2:
            # Use google-auth to refresh the access token (handles expiry/errors)
            try:
                creds = GoogleCredentials(
                    token=None,
                    refresh_token=refresh_token,
                    client_id=client_id,
                    client_secret=client_secret,
                    token_uri=token_url,
                )
                creds.refresh(GoogleRequest())
                access_token = creds.token
            except Exception as e:
                print(f"⚠️ Failed to obtain access token via google-auth: {e}")
                return 2

            if not access_token:
                print("⚠️ google-auth did not return an access_token.")
                return 2

        if smtp_port == 465:
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL(smtp_host, smtp_port, context=context) as server:
                if use_xoauth2:
                    auth_string = f"user={oauth_user}\x01auth=Bearer {access_token}\x01\x01"
                    auth_b64 = base64.b64encode(auth_string.encode()).decode()
                    code, resp = server.docmd("AUTH XOAUTH2 " + auth_b64)
                    if code != 235:
                        print(f"⚠️ XOAUTH2 authentication failed: {code} {resp}")
                        return 2
                else:
                    server.login(smtp_user, smtp_pass)

                server.send_message(msg, from_addr=email_from, to_addrs=recipients)
        else:
            with smtplib.SMTP(smtp_host, smtp_port, timeout=60) as server:
                server.ehlo()
                server.starttls(context=ssl.create_default_context())
                server.ehlo()
                if use_xoauth2:
                    auth_string = f"user={oauth_user}\x01auth=Bearer {access_token}\x01\x01"
                    auth_b64 = base64.b64encode(auth_string.encode()).decode()
                    code, resp = server.docmd("AUTH XOAUTH2 " + auth_b64)
                    if code != 235:
                        print(f"⚠️ XOAUTH2 authentication failed: {code} {resp}")
                        return 2
                else:
                    server.login(smtp_user, smtp_pass)

                server.send_message(msg, from_addr=email_from, to_addrs=recipients)
    except Exception as e:
        print(f"⚠️ Email notification failed: {e}")
        return 2

    print(f"✅ Email notification sent successfully to: {', '.join(recipients)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
