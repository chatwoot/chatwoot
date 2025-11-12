# Resend Ingress Setup Guide for Chatwoot

## Overview
This implementation adds native support for Resend inbound email webhooks to Chatwoot, allowing emails sent to your Resend address to automatically create conversations in Chatwoot.

## What's Been Added

### 1. Controller
**File:** `app/controllers/action_mailbox/ingresses/resend/inbound_emails_controller.rb`

Features:
- Accepts Resend's `email.received` webhook events
- Verifies HMAC SHA256 signature for security
- Fetches full email content from Resend API using email_id
- Converts JSON payload to RFC822 MIME format
- Supports both HTML and plain text emails
- Preserves email threading headers (Message-ID, In-Reply-To, References)
- Submits to ActionMailbox for normal Chatwoot processing
- Current limitations: Attachments not yet implemented

### 2. Routes
**File:** `config/routes.rb`

New endpoint: `POST /rails/action_mailbox/resend/inbound_emails`

### 3. Environment Variables
**File:** `.env.example`

Added configuration for:
- `RESEND_WEBHOOK_SECRET` - Required for webhook signature verification
- `RESEND_API_KEY` - Required for fetching full email content from Resend API

## Deployment Instructions

### Step 1: Review and Test Locally (Optional)
```bash
# Ensure you're on the feature branch
git branch
# Should show: * feature/resend-ingress

# Review changes
git diff develop
```

### Step 2: Commit Changes
```bash
# Stage all changes
git add app/controllers/action_mailbox/
git add config/routes.rb
git add .env.example

# Create commit
git commit -m "Add Resend ingress support for inbound emails

- Add custom ActionMailbox ingress controller for Resend webhooks
- Accept email.received events with HMAC signature verification
- Convert JSON payload to RFC822 MIME format
- Support plain text emails (MVP)
- Add Resend configuration to .env.example
- Add route: POST /rails/action_mailbox/resend/inbound_emails"
```

### Step 3: Push to GitHub
```bash
# Push feature branch
git push -u origin feature/resend-ingress
```

### Step 4: Merge to Develop Branch
```bash
# Switch to develop and merge
git checkout develop
git merge feature/resend-ingress
git push origin develop
```

This will trigger Heroku auto-deploy from the `develop` branch.

### Step 5: Configure Heroku Environment Variables
```bash
# REQUIRED: Set webhook secret (get this from Resend dashboard when creating webhook)
heroku config:set RESEND_WEBHOOK_SECRET=whsec_your_secret_here --app support-migrately-nl

# REQUIRED: Set API key to fetch full email content from Resend
# Get this from: https://resend.com/api-keys
heroku config:set RESEND_API_KEY=re_your_api_key_here --app support-migrately-nl

# Optional: Set ingress service (not required for Resend)
# heroku config:set RAILS_INBOUND_EMAIL_SERVICE=resend --app support-migrately-nl
```

### Step 6: Verify Deployment
```bash
# Check if route exists
heroku run rails routes --app support-migrately-nl | grep resend

# Expected output:
# POST /rails/action_mailbox/resend/inbound_emails action_mailbox/ingresses/resend/inbound_emails#create
```

### Step 7: Configure Resend Webhook
1. Go to Resend Dashboard: https://resend.com/webhooks
2. Click "Add Webhook"
3. Set webhook URL:
   ```
   https://support.migrately.nl/rails/action_mailbox/resend/inbound_emails
   ```
4. Select event: `email.received`
5. Save and copy the webhook secret
6. Update Heroku config with the secret (if not done in Step 5)

### Step 8: Test the Integration
```bash
# Send test email to your Resend address
# For example: support@migrately.nl

# Monitor Heroku logs
heroku logs --tail --app support-migrately-nl | grep resend

# Expected log output:
# Started POST "/rails/action_mailbox/resend/inbound_emails" for [IP] at [TIMESTAMP]
# Processing by ActionMailbox::Ingresses::Resend::InboundEmailsController#create as */*
# Completed 200 OK in XXms
```

### Step 9: Verify in Chatwoot
1. Log into Chatwoot: https://support.migrately.nl
2. Check for new conversation from the test email
3. Verify sender, subject, and message body appear correctly

## Rollback Instructions

If something goes wrong, you can easily revert:

### Option 1: Revert via Git
```bash
# On develop branch
git revert HEAD
git push origin develop
```

### Option 2: Restore Previous Commit
```bash
# Find the commit before the merge
git log --oneline

# Reset to that commit
git reset --hard <commit-hash>
git push origin develop --force
```

### Option 3: Delete Feature Branch Merge
```bash
# Switch to develop
git checkout develop

# Reset to before merge (find commit hash with git log)
git reset --hard <commit-before-merge>
git push origin develop --force
```

## Troubleshooting

### Issue: 404 on Webhook Endpoint
**Solution:** Verify route is registered
```bash
heroku run rails routes --app support-migrately-nl | grep resend
```

### Issue: 401 Unauthorized
**Solution:** Check webhook secret
```bash
heroku config:get RESEND_WEBHOOK_SECRET --app support-migrately-nl
```
Ensure it matches the secret in Resend dashboard.

### Issue: No Conversation Created
**Solution:** Check Heroku logs for errors
```bash
heroku logs --tail --app support-migrately-nl
```

Common causes:
- Invalid email format
- Missing required fields in webhook payload
- ActionMailbox routing issue

### Issue: Signature Verification Fails
**Causes:**
- Wrong webhook secret
- Request body was modified/parsed before verification
- Resend changed signature algorithm

**Debug:**
```bash
# Check logs for signature verification errors
heroku logs --tail --app support-migrately-nl | grep "Invalid signature"
```

## Current Implementation Status

What's implemented:
- ✅ Plain text emails
- ✅ HTML emails (multipart MIME)
- ✅ Email headers (From, To, CC, BCC, Subject)
- ✅ Threading headers (Message-ID, In-Reply-To, References)
- ✅ HMAC SHA256 signature verification
- ✅ Fetches full email content from Resend API

What's NOT yet implemented:
- ❌ Attachments (download and embed in MIME message)
- ❌ Inline images (requires attachment handling)

## Future Enhancements

1. **Attachment Support** (Next Priority)
   - Fetch attachment metadata from email response
   - Download attachment content from Resend CDN using `download_url`
   - Embed attachments in MIME message using Mail gem
   - Support both inline images (Content-ID) and regular attachments

2. **Advanced Features**
   - Rate limiting for Resend API calls
   - Caching of downloaded attachments
   - Retry logic for failed API calls
   - Better error handling and logging

## Architecture Notes

### Why Two-Step Process?
Resend's webhook only sends metadata (no body/attachments). Full email content requires a separate API call. For MVP, we use the `text` field from the webhook payload.

### Why Custom Ingress?
Rails ActionMailbox doesn't have a built-in Resend adapter. This implementation follows the same pattern as Mailgun/Postmark ingresses.

### Security
- HMAC SHA256 signature verification prevents unauthorized webhooks
- Secure comparison prevents timing attacks
- CSRF protection disabled (webhook endpoint)

## Support

For issues or questions:
- GitHub Issues: https://github.com/rcoenen/chatwoot/issues
- Original Chatwoot Docs: https://www.chatwoot.com/docs/

## License

This implementation follows Chatwoot's open-source license.
