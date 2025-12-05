# Quick Reference: WhatsApp Web Integration

## TL;DR

Add WhatsApp Web as a new provider that uses Go WhatsApp Web Multidevice service via REST API with Basic Auth and HMAC-verified webhooks.

## One-Minute Overview

**What**: New WhatsApp provider using WhatsApp Web protocol (no Business API needed)
**How**: REST API integration with Go WhatsApp Web Multidevice service
**Auth**: HTTP Basic Auth for API calls, HMAC SHA256 for webhooks
**Login**: QR code or pairing code (user scans on mobile)

## Files to Create/Modify

### Backend (Ruby)

```ruby
# 1. MODEL UPDATE
app/models/channel/whatsapp.rb
  + Add 'whatsapp_web' to PROVIDERS
  + Update provider_service method
  + Update ensure_webhook_verify_token

# 2. PROVIDER SERVICE (NEW)
app/services/whatsapp/providers/whatsapp_web_service.rb
  + send_message(phone, message)
  + send_template(phone, template, message) → nil
  + sync_templates() → []
  + validate_provider_config?() → GET /app/devices
  + api_headers() → Basic Auth
  + media_url(media_path) → {base_url}/{path}

# 3. INCOMING MESSAGE SERVICE (NEW)
app/services/whatsapp/incoming_message_multidevice_service.rb
  + Process all webhook event types
  + Handle text, media, reactions, receipts, groups
  + Download media from Go WhatsApp service

# 4. JOB UPDATE
app/jobs/webhooks/whatsapp_events_job.rb
  + Add when 'whatsapp_web' case

# 5. CONTROLLER UPDATE
app/controllers/webhooks/whatsapp_controller.rb
  + Add verify_multidevice_signature method
  + HMAC SHA256 verification using X-Hub-Signature-256
```

### Frontend (Vue 3)

```vue
<!-- 1. PROVIDER CONFIG COMPONENT (NEW) -->
app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappMultidevice.vue
  - Form fields: name, phone, api_base_url, username, password
  - Validation: required, E.164 phone, valid URL
  - Submit to POST /inboxes with provider: 'whatsapp_web'

<!-- 2. PROVIDER SELECTION UPDATE -->
app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Whatsapp.vue
  + Add WHATSAPP_MULTIDEVICE to PROVIDER_TYPES
  + Add to availableProviders array
  + Add WhatsappMultidevice component import/registration

<!-- 3. I18N (NEW) -->
app/javascript/dashboard/i18n/locale/en/inboxMgmt.json
  + ADD.WHATSAPP_MULTIDEVICE.* translations
```

### Tests

```ruby
# Backend tests
spec/services/whatsapp/providers/whatsapp_web_service_spec.rb
spec/services/whatsapp/incoming_message_multidevice_service_spec.rb
spec/controllers/webhooks/whatsapp_controller_spec.rb

# Frontend tests
app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappMultidevice.spec.js
```

## Key Code Snippets

### Provider Config Structure

```ruby
{
  api_base_url: "http://localhost:3000",
  basic_auth_username: "admin",
  basic_auth_password: "secret123",
  webhook_verify_token: SecureRandom.hex(16) # Auto-generated
}
```

### Basic Auth Header

```ruby
def api_headers
  username = whatsapp_channel.provider_config['basic_auth_username']
  password = whatsapp_channel.provider_config['basic_auth_password']

  {
    'Authorization' => "Basic #{Base64.strict_encode64("#{username}:#{password}")}",
    'Content-Type' => 'application/json'
  }
end
```

### Send Text Message

```ruby
def send_text_message(phone_number, message)
  response = HTTParty.post(
    "#{api_base_url}/send/message",
    headers: api_headers,
    body: {
      phone: ensure_jid_format(phone_number),
      message: message.outgoing_content
    }.to_json
  )

  process_response(response, message)
end
```

### HMAC Webhook Verification

```ruby
def verify_multidevice_signature(channel)
  signature = request.headers['X-Hub-Signature-256']
  return false if signature.blank?

  webhook_secret = channel.provider_config['webhook_verify_token'] || 'secret'
  payload = request.raw_post

  expected = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload)
  received = signature.sub('sha256=', '')

  ActiveSupport::SecurityUtils.secure_compare(expected, received)
end
```

### Webhook Event Processing

```ruby
def extract_message_content
  # Text message
  if params.dig(:message, :text).present?
    { type: 'text', body: params.dig(:message, :text) }

  # Image message
  elsif params[:image].present?
    {
      type: 'image',
      url: params.dig(:image, :media_path),
      caption: params.dig(:image, :caption)
    }

  # Receipt event
  elsif params[:event] == 'message.ack'
    receipt_type = params.dig(:payload, :receipt_type)
    message_ids = params.dig(:payload, :ids)
    update_message_status(message_ids, receipt_type)
    nil # Don't create new message

  # ... other types
  end
end
```

## API Endpoints Reference

### Go WhatsApp Service Endpoints

```bash
# Validate connection (used in provider validation)
GET {api_base_url}/app/devices
→ Returns: { code: "SUCCESS", ... }

# Send text message
POST {api_base_url}/send/message
Body: { phone: "628xxx@s.whatsapp.net", message: "Hello" }
→ Returns: { results: { message_id: "ABC123" } }

# Send image
POST {api_base_url}/send/image
Body (multipart): { phone, image_url, caption, compress: false }
→ Returns: { results: { message_id: "IMG123" } }

# Download media
GET {api_base_url}/statics/media/{filename}
→ Returns: binary file data
```

### Chatwoot Endpoints

```bash
# Webhook endpoint
POST /webhooks/whatsapp/:phone_number
Headers: X-Hub-Signature-256: sha256={hmac}
Body: { from, message, ... }
→ Returns: 200 OK or 401 Unauthorized
```

## Webhook Payload Examples

### Text Message

```json
{
  "from": "628123456789@s.whatsapp.net",
  "sender_id": "628123456789",
  "pushname": "John Doe",
  "timestamp": "2023-10-15T10:30:00Z",
  "message": {
    "text": "Hello Chatwoot",
    "id": "MSG123"
  }
}
```

### Image Message

```json
{
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T10:35:00Z",
  "message": { "id": "IMG123" },
  "image": {
    "media_path": "statics/media/1752404751-uuid.jpe",
    "mime_type": "image/jpeg",
    "caption": "Check this!"
  }
}
```

### Receipt Event

```json
{
  "event": "message.ack",
  "payload": {
    "chat_id": "628123456789@s.whatsapp.net",
    "ids": ["MSG123"],
    "receipt_type": "read"
  },
  "timestamp": "2023-10-15T10:40:00Z"
}
```

### Group Event

```json
{
  "event": "group.participants",
  "payload": {
    "chat_id": "120363xxx@g.us",
    "type": "join",
    "jids": ["628123456789@s.whatsapp.net"]
  },
  "timestamp": "2023-10-15T11:00:00Z"
}
```

## Configuration Commands

### Go WhatsApp Service Setup

```bash
# Start service with webhook
./whatsapp rest \
  --port 3000 \
  --basic-auth="admin:secret123" \
  --webhook="https://chatwoot.example.com/webhooks/whatsapp/+1234567890" \
  --webhook-secret="matching_webhook_verify_token"

# Or with Docker
docker run -d \
  -p 3000:3000 \
  -v ./storage:/app/storages \
  -e APP_BASIC_AUTH=admin:secret123 \
  -e WHATSAPP_WEBHOOK=https://chatwoot.example.com/webhooks/whatsapp/+1234567890 \
  -e WHATSAPP_WEBHOOK_SECRET=matching_webhook_verify_token \
  ghcr.io/chatwoot-br/go-whatsapp-web-multidevice:latest
```

### Test Connection

```bash
# Test API access
curl -u admin:secret123 http://localhost:3000/app/devices

# Test message send
curl -X POST http://localhost:3000/send/message \
  -u admin:secret123 \
  -H "Content-Type: application/json" \
  -d '{"phone":"628xxx@s.whatsapp.net","message":"Test"}'
```

## Testing Checklist

### Unit Tests

```ruby
# Provider service
✓ validate_provider_config? returns true when API accessible
✓ validate_provider_config? returns false when API unreachable
✓ send_message sends text successfully
✓ send_message handles attachments
✓ api_headers returns correct Basic Auth
✓ media_url constructs correct URL

# Incoming message service
✓ Creates message from text webhook
✓ Creates message with attachment from image webhook
✓ Updates status from receipt webhook
✓ Handles group events
✓ Handles unknown event types gracefully

# Webhook controller
✓ Accepts webhook with valid HMAC signature
✓ Rejects webhook with invalid signature
✓ Rejects webhook without signature
```

### Integration Tests

```ruby
✓ End-to-end message flow (send → receive → display)
✓ Media download and attachment creation
✓ Receipt status updates (delivered → read)
✓ Error handling for failed API calls
✓ Timeout handling for slow responses
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Cannot connect to WhatsApp service" | Check API base URL, ensure service is running |
| "Authentication failed" | Verify Basic Auth username/password match |
| "Signature verification failed" | Ensure webhook_verify_token matches on both sides |
| "Messages not sending" | Check WhatsApp is logged in (QR/pairing code) |
| "Media not loading" | Verify FFmpeg installed, check media path format |
| "Webhooks not received" | Check network connectivity, firewall rules |

## Environment Variables

```bash
# Go WhatsApp Service
APP_PORT=3000
APP_BASIC_AUTH=admin:password
WHATSAPP_WEBHOOK=https://chatwoot.example.com/webhooks/whatsapp/+1234567890
WHATSAPP_WEBHOOK_SECRET=your_webhook_secret

# Chatwoot (optional, uses provider_config instead)
# These are stored in database provider_config JSONB field
```

## Phone Number Format

```ruby
# Input formats accepted
"+1234567890"           # E.164 format (UI validation)
"1234567890"            # Plain number

# JID format for API (auto-added by service)
"+1234567890@s.whatsapp.net"  # Individual chat
"120363xxx@g.us"              # Group chat

# Helper method
def ensure_jid_format(phone)
  phone.include?('@') ? phone : "#{phone}@s.whatsapp.net"
end
```

## Security Checklist

- [x] HMAC signature verification on all webhooks
- [x] Timing-safe signature comparison
- [x] Basic Auth credentials stored encrypted
- [x] Webhook secret auto-generated (32-byte hex)
- [x] HTTPS required in production
- [x] No sensitive data in logs
- [x] Rate limiting on webhook endpoint
- [x] Invalid signature logged for monitoring

## Deployment Steps

1. **Deploy Go WhatsApp Service**
   ```bash
   docker-compose up -d whatsapp-service
   ```

2. **Login to WhatsApp**
   - Open service UI: http://localhost:3000
   - Scan QR code with WhatsApp mobile app

3. **Deploy Chatwoot Changes**
   ```bash
   git pull
   bundle install && pnpm install
   rails db:migrate  # (none needed for this feature)
   rails restart
   ```

4. **Create Inbox**
   - Settings → Inboxes → Add Inbox
   - Select WhatsApp → WhatsApp Web
   - Fill configuration
   - Test by sending message

5. **Verify Webhooks**
   - Send message from customer WhatsApp
   - Check Rails logs for webhook receipt
   - Verify message appears in conversation

## Performance Targets

| Metric | Target |
|--------|--------|
| Message send time | < 2 seconds |
| Webhook processing | < 1 second |
| Media download | < 5 seconds (10MB) |
| API connection validation | < 3 seconds |
| Signature verification | < 100ms |

## Documentation Links

- [Full Implementation Story](./implementation-story.md)
- [Provider Pattern Guide](./creating-whatsapp-inbox-provider.md)
- [Deployment Guide](./deployment-guide.md)
- [Webhook Payload Docs](./webhook-payload.md)
- [API Reference](./openapi.md)
- [Architecture Diagrams](./architecture-diagram.md)

## Support

- GitHub Issues: https://github.com/chatwoot/chatwoot/issues
- Community: https://community.chatwoot.com
- Discord: https://discord.gg/chatwoot

---

**Quick Reference Version**: 1.0
**Last Updated**: 2025-10-05
**Print & Keep Handy!**
