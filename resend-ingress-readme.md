# Resend Ingress for Chatwoot Action Mailbox

This document outlines the plan to add Resend as a supported ingress for Rails Action Mailbox in Chatwoot.

## Current Status

Chatwoot currently supports the following Action Mailbox ingresses:
- Sendgrid
- Mailgun
- Mandrill
- Postmark
- Relay (Exim, Postfix, Qmail)

**Resend is not currently supported**, which causes webhook calls to `/rails/action_mailbox/resend/inbound_emails` to return 404.

## Implementation Plan

To add Resend ingress support, we need to:

1. **Create Resend Ingress Controller**
   - Path: `app/mailboxes/application_mailbox.rb` or similar
   - Handle Resend webhook payload format
   - Parse incoming email data from Resend's webhook

2. **Add Routing**
   - Add route: `POST /rails/action_mailbox/resend/inbound_emails`
   - Map to Resend ingress controller

3. **Configure Environment Variables**
   - `RAILS_INBOUND_EMAIL_SERVICE=resend`
   - `RAILS_INBOUND_EMAIL_PASSWORD=<resend_api_key>`

4. **Webhook Verification**
   - Implement Resend webhook signature verification
   - Use `whsec_*` signing secret from Resend

## Resend Webhook Payload Format

Resend sends webhooks with the following structure:

```json
{
  "type": "email.received",
  "created_at": "2025-11-11T21:04:54.000Z",
  "data": {
    "email_id": "67b6a321-b1d9-4a69-8b82-2ff3b45c717b",
    "from": "sender@example.com",
    "to": ["recipient@example.com"],
    "cc": [],
    "bcc": [],
    "subject": "Email subject",
    "message_id": "<message-id>",
    "attachments": [],
    "created_at": "2025-11-11T21:04:58.036Z"
  }
}
```

## References

- [Rails Action Mailbox Documentation](https://guides.rubyonrails.org/action_mailbox_basics.html)
- [Resend Inbound Email Documentation](https://resend.com/docs/webhooks)
- [Chatwoot Email Channel Documentation](https://www.chatwoot.com/docs/self-hosted/configuration/features/email-channel/conversation-continuity/)

## Current Workaround

Until Resend ingress is implemented, Chatwoot can receive emails via IMAP from the Resend mailbox:
- IMAP Server: `imap.resend.com`
- SMTP Server: `smtp.resend.com`
- Port: 993 (IMAP), 465 (SMTP)

---

**Status:** Planned for implementation
**Priority:** High (needed for webhook-based email receiving)
**Last Updated:** 2025-11-11
