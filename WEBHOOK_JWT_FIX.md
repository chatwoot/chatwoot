# Apple Messages for Business - JWT Verification Fix

## Issue Discovered

After deploying the webhook refactoring, webhooks were returning **403 Forbidden** due to JWT verification failures.

## Root Cause

The JWT token sent by Apple contains an `aud` (audience) claim with the MSP ID configured in Apple Business Register. This MSP ID must match the `msp_id` stored in the Chatwoot channel for JWT verification to succeed.

### The Problem

- **Apple Business Register** was configured with MSP ID: `c7b1f0cf-c3fd-40ab-8d40-cff3d81d1d6b`
- **Channel 10** in production had MSP ID: `cb77f14e-f253-4e5c-9efd-5108d9b13f27` (different!)
- **JWT verification failed** because the token's `aud` didn't match the channel's `msp_id`

### Error Logs

```
[AMB Webhook] JWT verification failed for MSP ID: cb77f14e-f253-4e5c-9efd-5108d9b13f27: Signature verification failed
[AMB Webhook] Full token: eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NTk3NDAxNjYsImF1ZCI6ImM3YjFmMGNmLWMzZmQtNDBhYi04ZDQwLWNmZjNkODFkMWQ2YiJ9...
```

Decoded JWT payload:
```json
{
  "iat": 1759740166,
  "aud": "c7b1f0cf-c3fd-40ab-8d40-cff3d81d1d6b"  // ← This is the MSP ID from Apple
}
```

## Solution

Updated channel 10's MSP ID to match what Apple is using:

```bash
ssh root@msp.rhaps.net "docker exec chatwoot-web bundle exec rails runner \
  'c = Channel::AppleMessagesForBusiness.find(10); \
   c.update!(msp_id: \"c7b1f0cf-c3fd-40ab-8d40-cff3d81d1d6b\")'"
```

## How the Refactored Webhook Works

### 1. Apple sends webhook request
```
POST https://msp.rhaps.net/webhooks/apple_messages_for_business/message
Headers:
  - destination-id: 8dfad34f-3c1e-4dbf-a9b6-7a189f186692  (business_id)
  - authorization: Bearer <JWT_TOKEN>
```

### 2. Chatwoot finds channel by business_id
```ruby
business_id = request.headers['destination-id']
@channel = Channel::AppleMessagesForBusiness.find_by(business_id: business_id)
# Found channel 10 with business_id: 8dfad34f-3c1e-4dbf-a9b6-7a189f186692
```

### 3. JWT verification uses channel's msp_id
```ruby
token = request.headers['authorization'].sub('Bearer ', '')
@channel.verify_jwt_token(token)  # Uses @channel.msp_id and @channel.secret
```

### 4. JWT verification process
```ruby
# In AppleMessagesForBusiness::JwtService
JWT.decode(
  token,
  secret,  # Channel's secret
  true,
  {
    algorithm: 'HS256',
    aud: msp_id,  # Must match token's 'aud' claim
    verify_aud: true
  }
)
```

## Key Takeaways

1. **MSP ID consistency is critical**: The MSP ID in Chatwoot must match what's configured in Apple Business Register

2. **Business ID for routing**: The refactored webhook uses `business_id` (from `destination-id` header) to find the channel

3. **MSP ID for verification**: The `msp_id` is still used for JWT verification (must match token's `aud` claim)

4. **One MSP ID per Apple Business Register account**: All channels using the same Apple Business Register account must use the same MSP ID

## Production Channels Status

After fix:
```
Channel 3:  MSP: 7a2052d5-cf35-41db-add5-d9a0a519f852, Business: 6bd9daae-2bb3-41a5-8ed1-7c654986c537
Channel 5:  MSP: 7a2052d5-cf35-41db-add5-d9a0a519f852, Business: c8b5b1a9-e674-4466-aa4a-ebde810bf341
Channel 6:  MSP: 7a2052d5-cf35-41db-add5-d9a0a519f852, Business: d9c5c108-5137-4396-9aa2-961f2a5104e6
Channel 7:  MSP: c7b1f0cf-c3fd-40ab-8d40-cff3d81d1d6b, Business: b0566171-3c85-4eff-b0fb-dcab6bc5cdc6
Channel 8:  MSP: cb77f14e-f253-4e5c-9efd-5108d9b13f27, Business: 9f29f310-fbdc-4fcc-be1f-e2ff445b806f
Channel 9:  MSP: cb77f14e-f253-4e5c-9efd-5108d9b13f27, Business: 645c0407-715d-4c19-b3d4-2d1164d4d861
Channel 10: MSP: c7b1f0cf-c3fd-40ab-8d40-cff3d81d1d6b, Business: 8dfad34f-3c1e-4dbf-a9b6-7a189f186692 ✅ FIXED
```

## Testing

Send a message from your Apple device to business ID `8dfad34f-3c1e-4dbf-a9b6-7a189f186692` and verify:

1. ✅ Webhook receives request at `/webhooks/apple_messages_for_business/message`
2. ✅ Channel is found by business_id from `destination-id` header
3. ✅ JWT verification succeeds (token's `aud` matches channel's `msp_id`)
4. ✅ Message is processed and appears in Chatwoot

## Monitoring

```bash
# Watch for webhook requests
ssh root@msp.rhaps.net "cd /opt/chatwoot && docker compose -f docker-compose.production.yml logs web -f | grep 'AMB Webhook'"

# Check for JWT errors
ssh root@msp.rhaps.net "cd /opt/chatwoot && docker compose -f docker-compose.production.yml logs web --tail=100 | grep -i 'JWT\|403'"
```

---

**Issue Resolved**: October 6, 2025  
**Root Cause**: MSP ID mismatch between Chatwoot channel and Apple Business Register configuration  
**Solution**: Updated channel's MSP ID to match Apple's JWT token audience claim