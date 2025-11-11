# Resend Ingress Setup Guide for Chatwoot

## Overview
This implementation adds native support for Resend inbound email webhooks to Chatwoot, allowing emails sent to your Resend address to automatically create conversations in Chatwoot.

## What's Been Added

### 1. Controller
**File:** `app/controllers/action_mailbox/ingresses/resend/inbound_emails_controller.rb`

Features:
- Accepts Resend's `email.received` webhook events
- Verifies HMAC SHA256 signature for security
- Converts JSON payload to RFC822 MIME format
- Submits to ActionMailbox for normal Chatwoot processing
- MVP: Plain text emails only (HTML and attachments in future enhancement)

### 2. Routes
**File:** `config/routes.rb`

New endpoint: `POST /rails/action_mailbox/resend/inbound_emails`

### 3. Environment Variables
**File:** `.env.example`

Added configuration for:
- `RESEND_WEBHOOK_SECRET` - Required for signature verification
- `RESEND_API_KEY` - Optional, for future enhancements

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
# Set webhook secret (get this from Resend dashboard)
heroku config:set RESEND_WEBHOOK_SECRET=whsec_your_secret_here --app support-migrately-nl

# Optional: Set API key for future enhancements
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

## MVP Limitations

Current implementation (MVP):
- ✅ Plain text emails
- ✅ Basic headers (From, To, Subject)
- ✅ HMAC signature verification
- ❌ HTML emails (not yet supported)
- ❌ Attachments (not yet supported)
- ❌ Email threading (Message-ID, In-Reply-To not yet preserved)

## Future Enhancements

1. **HTML Email Support**
   - Build multipart MIME messages (text/plain + text/html)

2. **Attachment Support**
   - Use Resend API to fetch attachment content
   - Embed attachments in MIME message

3. **Full Email Content**
   - Call Resend API `/emails/{email_id}` to get complete email
   - Preserve all headers for proper threading

4. **Email Threading**
   - Extract and preserve Message-ID, In-Reply-To, References headers
   - Enable conversation continuity

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
