# Apple Messages for Business Webhook Refactoring

## Overview

Refactored the Apple Messages for Business (AMB) webhook endpoint to use a **permanent URL without MSP ID** in the path. This makes the integration more scalable and aligns with Apple Business Register's requirement for a permanent webhook URL.

## Problem

The previous implementation used MSP ID in the webhook URL path:
- **Old URL format**: `/webhooks/apple_messages_for_business/{msp_id}/message`
- **Issue**: Apple Business Register expects a permanent webhook URL configured upfront, but the MSP ID is not provided until after configuration

## Solution

Changed to a permanent webhook URL that works for all channels:
- **New URL format**: `/webhooks/apple_messages_for_business`
- **Channel identification**: Uses the `business_id` from the `destination-id` header sent by Apple
- **Scalability**: Single webhook URL works for all Apple Messages for Business channels

## Changes Made

### 1. Routes (`config/routes.rb`)
```ruby
# Before:
post 'webhooks/apple_messages_for_business/:msp_id', to: 'webhooks/apple_messages_for_business#process_payload'
post 'webhooks/apple_messages_for_business/:msp_id/message', to: 'webhooks/apple_messages_for_business#process_payload'

# After:
# Apple appends /message to the base URL configured in Apple Business Register
post 'webhooks/apple_messages_for_business/message', to: 'webhooks/apple_messages_for_business#process_payload'
# Also support base URL without /message for flexibility
post 'webhooks/apple_messages_for_business', to: 'webhooks/apple_messages_for_business#process_payload'
```

### 2. Webhook Controller (`app/controllers/webhooks/apple_messages_for_business_controller.rb`)

**Changed `find_channel` method:**
```ruby
# Before: Extract MSP ID from URL path
msp_id = request.path.split('/')[3]
@channel = Channel::AppleMessagesForBusiness.find_by(msp_id: msp_id)

# After: Extract business_id from destination-id header
business_id = request.headers['destination-id']
@channel = Channel::AppleMessagesForBusiness.find_by(business_id: business_id)
```

### 3. Channel Model (`app/models/channel/apple_messages_for_business.rb`)

**Updated `setup_webhook_url` method:**
```ruby
# Before:
self.webhook_url = "#{base_url}/webhooks/apple_messages_for_business/#{msp_id}/message"

# After:
self.webhook_url = "#{base_url}/webhooks/apple_messages_for_business"
```

### 4. Initializer (`config/initializers/apple_messages_for_business.rb`)

**Updated webhook URL generation:**
```ruby
# Before:
new_webhook_url = "#{base_url}/webhooks/apple_messages_for_business/#{channel.msp_id}"

# After:
new_webhook_url = "#{base_url}/webhooks/apple_messages_for_business"
```

### 5. Utility Scripts

Updated the following scripts to use the permanent webhook URL:
- `docs/apple-messages/scripts/utilities/update_apple_webhook_url.rb`
- `docs/apple-messages/scripts/utilities/check_apple_config.rb`

## How It Works

1. **Configure base URL in Apple Business Register**: `https://your-domain.com/webhooks/apple_messages_for_business`

2. **Apple appends `/message`** and sends webhook request to: `https://your-domain.com/webhooks/apple_messages_for_business/message`

3. **Apple includes headers** with each request:
   - `destination-id`: Contains the `business_id` (unique identifier for the channel)
   - `source-id`: Contains the user's opaque ID
   - `authorization`: Contains the JWT token for verification

4. **Chatwoot identifies the channel** by looking up the `business_id` from the `destination-id` header

5. **JWT verification** still uses the channel's MSP ID and secret

## Benefits

✅ **Scalable**: Single webhook URL works for all channels  
✅ **Apple-compliant**: Permanent URL can be configured in Apple Business Register upfront  
✅ **Simpler**: No need to manage different webhook URLs per MSP ID  
✅ **Maintainable**: Easier to configure and troubleshoot  

## Migration Notes

### For Existing Channels

The initializer will automatically update existing channels to use the new permanent webhook URL on server restart.

### For Apple Business Register

Update your webhook configuration in Apple Business Register to the **base URL**:
```
https://your-domain.com/webhooks/apple_messages_for_business
```

**Important**: Apple will automatically append `/message` to this URL when sending webhooks, so the actual endpoint will be:
```
https://your-domain.com/webhooks/apple_messages_for_business/message
```

This single base URL will handle webhooks for all your Apple Messages for Business channels.

## Testing

To verify the changes:

1. **Check routes**:
   ```bash
   bundle exec rails routes | grep apple_messages_for_business
   ```

2. **Check channel configuration**:
   ```bash
   rails runner docs/apple-messages/scripts/utilities/check_apple_config.rb
   ```

3. **Update webhook URL** (if needed):
   ```bash
   rails runner docs/apple-messages/scripts/utilities/update_apple_webhook_url.rb
   ```

4. **Monitor webhook requests**:
   ```bash
   tail -f log/development.log | grep 'AMB Webhook'
   ```

## Technical Details

### Database Schema
The `channel_apple_messages_for_business` table has:
- `msp_id`: MSP identifier (still used for JWT)
- `business_id`: Business identifier (now used for webhook routing) - **UNIQUE**
- Both fields are required and indexed

### Header Mapping
According to Apple's MSP REST API documentation:
- Incoming messages include `destinationId` in the payload (the business ID)
- The `destination-id` header also contains the business ID
- The `source-id` header contains the user's opaque ID

### Backward Compatibility
The old routes with MSP ID have been removed. All channels must use the new permanent webhook URL.

## Related Files

- Routes: `config/routes.rb`
- Controller: `app/controllers/webhooks/apple_messages_for_business_controller.rb`
- Model: `app/models/channel/apple_messages_for_business.rb`
- Initializer: `config/initializers/apple_messages_for_business.rb`
- Utility scripts: `docs/apple-messages/scripts/utilities/`