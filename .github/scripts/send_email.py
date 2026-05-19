#!/usr/bin/env python3
"""Send an HTML email using only the Python standard library.

Reads the HTML body from /tmp/email_report.html by default and sends via SMTP.
Environment variables used:
  SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, EMAIL_FROM, EMAIL_TO

Exits with 0 on success, non-zero on failure.
"""
import os
import sys
import smtplib
import ssl
from email.message import EmailMessage


def main():
    smtp_host = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    smtp_user = os.environ.get("SMTP_USERNAME")
    smtp_pass = os.environ.get("SMTP_PASSWORD")
    email_from = os.environ.get("EMAIL_FROM") or smtp_user
    email_to = os.environ.get("EMAIL_TO") or smtp_user

    if not smtp_user or not smtp_pass:
        print("⚠️ SMTP credentials not configured. Skipping email notification.")
        print("Set SMTP_USERNAME and SMTP_PASSWORD to enable email sending.")
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
        if smtp_port == 465:
            context = ssl.create_default_context()
            with smtplib.SMTP_SSL(smtp_host, smtp_port, context=context) as server:
                server.login(smtp_user, smtp_pass)
                server.send_message(msg, from_addr=email_from, to_addrs=recipients)
        else:
            with smtplib.SMTP(smtp_host, smtp_port, timeout=60) as server:
                server.ehlo()
                server.starttls(context=ssl.create_default_context())
                server.ehlo()
                server.login(smtp_user, smtp_pass)
                server.send_message(msg, from_addr=email_from, to_addrs=recipients)
    except Exception as e:
        print(f"⚠️ Email notification failed: {e}")
        return 2

    print(f"✅ Email notification sent successfully to: {', '.join(recipients)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
