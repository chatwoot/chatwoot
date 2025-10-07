# Apple Messages for Business Webhook Deployment Guide

## Summary of Changes

We've refactored the Apple Messages for Business webhook endpoint to use a **permanent URL** that doesn't include the MSP ID in the path. This makes the integration scalable and compliant with Apple Business Register requirements.

## What Changed

### Before
- Webhook URL: `https://msp.rhaps.net/webhooks/apple_messages_for_business/{msp_id}/message`
- Each channel required a unique webhook URL
- MSP ID was extracted from the URL path

### After
- Webhook URL: `https://msp.rhaps.net/webhooks/apple_messages_for_business`
- Single permanent webhook URL for all channels
- Business ID is extracted from the `destination-id` header sent by Apple
- Apple automatically appends `/message` to the configured base URL

## Deployment Steps

### 1. Deploy Backend Changes
```bash
./deploy-backend-changes.sh
```

This script:
- Syncs backend code (routes, controllers, models, initializers) to production server
- Copies updated files into running Docker containers
- Restarts web and worker services
- Verifies the new routes are loaded

### 2. Update Apple Business Register

Configure the webhook URL in Apple Business Register:

**Base URL to configure:**
```
https://msp.rhaps.net/webhooks/apple_messages_for_business
```

**Important:** Apple will automatically append `/message`, so the actual endpoint will be:
```
https://msp.rhaps.net/webhooks/apple_messages_for_business/message
```

### 3. Update Existing Channels (Automatic)

The initializer will automatically update all existing channels on server restart:
- Old URL: `https://msp.rhaps.net/webhooks/apple_messages_for_business/{msp_id}/message`
- New URL: `https://msp.rhaps.net/webhooks/apple_messages_for_business`

## Verification

### Check Routes
```bash
ssh root@msp.rhaps.net "docker exec chatwoot-web bundle exec rails routes | grep apple_messages_for_business"
```

Expected output:
```
POST /webhooks/apple_messages_for_business/message
POST /webhooks/apple_messages_for_business
```

### Monitor Webhook Requests
```bash
ssh root@msp.rhaps.net "cd /opt/chatwoot && docker compose -f docker-compose.production.yml logs web -f | grep 'AMB Webhook'"
```

### Test Webhook
Send a test message from your Apple device to verify:
1. Webhook receives the request
2. Channel is identified by `business_id` from `destination-id` header
3. Message is processed correctly

## Technical Details

### How Channel Identification Works

1. **Apple sends webhook** to: `https://msp.rhaps.net/webhooks/apple_messages_for_business/message`

2. **Headers included:**
   - `destination-id`: Contains the `business_id` (unique per channel)
   - `source-id`: Contains the user's opaque ID
   - `authorization`: Contains JWT token for verification

3. **Chatwoot identifies channel:**
   ```ruby
   business_id = request.headers['destination-id']
   @channel = Channel::AppleMessagesForBusiness.find_by(business_id: business_id)
   ```

4. **JWT verification** uses the channel's `msp_id` and `secret`

### Files Modified

- `config/routes.rb` - Updated webhook routes
- `app/controllers/webhooks/apple_messages_for_business_controller.rb` - Changed channel lookup logic
- `app/models/channel/apple_messages_for_business.rb` - Updated webhook URL generation
- `config/initializers/apple_messages_for_business.rb` - Updated auto-configuration
- `docs/apple-messages/scripts/utilities/*.rb` - Updated utility scripts

## Rollback Plan

If issues occur, you can rollback by:

1. **Revert code changes:**
   ```bash
   git revert HEAD
   ./deploy-backend-changes.sh
   ```

2. **Update Apple Business Register** back to the old URL format with MSP ID

## Benefits

✅ **Scalable**: Single webhook URL for all channels  
✅ **Apple-compliant**: Permanent URL can be configured upfront  
✅ **Simpler**: No need to manage different URLs per MSP ID  
✅ **Maintainable**: Easier to configure and troubleshoot  

## Support

For issues or questions:
- Check logs: `ssh root@msp.rhaps.net "docker exec chatwoot-web tail -f /app/log/production.log"`
- Review documentation: `APPLE_WEBHOOK_REFACTORING.md`
- Monitor webhooks: Look for `[AMB Webhook]` log entries

---

**Deployment Date**: October 6, 2025  
**Production URL**: https://msp.rhaps.net  
**Webhook Endpoint**: https://msp.rhaps.net/webhooks/apple_messages_for_business