# FEAT-004: WhatsApp Web Provider Integration

## Overview

This feature adds support for the **Go WhatsApp Web Multidevice** application as a new WhatsApp provider in Chatwoot, enabling users to connect WhatsApp using the Web protocol without requiring WhatsApp Business API credentials.

## Documentation Index

### Implementation Resources

1. **[Implementation Story](./implementation-story.md)**
   - Complete user story with acceptance criteria
   - Technical implementation details
   - Testing requirements and edge cases
   - Configuration examples and success metrics
   - **START HERE** for understanding the complete feature scope

2. **[Creating WhatsApp Inbox Provider Guide](./creating-whatsapp-inbox-provider.md)**
   - Architecture overview of Chatwoot's WhatsApp provider pattern
   - Step-by-step guide for implementing new providers
   - Backend and frontend implementation checklist
   - Testing strategies and best practices

3. **[Deployment Guide](./deployment-guide.md)**
   - How to deploy the Go WhatsApp Web Multidevice service
   - Installation methods (binary, Docker, Kubernetes)
   - Configuration options and environment variables
   - Production deployment scenarios

4. **[Webhook Payload Documentation](./webhook-payload.md)**
   - Complete webhook event types and payloads
   - HMAC signature verification examples
   - Message types (text, media, contacts, locations)
   - Receipt events (delivered, read, played)
   - Group events (join, leave, promote, demote)
   - Protocol events (delete, revoke, edit)

5. **[API Reference](./openapi.md)**
   - Complete API documentation for AI agents
   - Authentication and phone number formats
   - All endpoint categories (app, user, send, message, chat, group)
   - Request/response examples
   - Common patterns and best practices

### Known Issues

1. **[ISSUE-001: Message Loss on Profile Picture Fetch](./ISSUE-001-message-loss-on-profile-picture-fetch.md)**
   - Critical bug causing message loss in production
   - Gateway panic on PrivacyToken in whatsmeow library
   - Connection refused errors during gateway restarts
   - Proposed solutions and workarounds

## Quick Start for Developers

### Understanding the Feature

1. Read the **[Implementation Story](./implementation-story.md)** sections:
   - Story Overview (lines 1-100)
   - Acceptance Criteria (lines 101-250)
   - Technical Implementation Details (lines 251-600)

2. Review the **[Provider Pattern Guide](./creating-whatsapp-inbox-provider.md)**:
   - Architecture Overview (lines 15-56)
   - Backend Implementation (lines 58-303)
   - Frontend Implementation (lines 318-516)

### Setting Up Development Environment

1. **Deploy Go WhatsApp Service** (see [Deployment Guide](./deployment-guide.md)):
   ```bash
   # Download binary
   wget https://github.com/chatwoot-br/go-whatsapp-web-multidevice/releases/latest/download/whatsapp-linux-amd64
   chmod +x whatsapp-linux-amd64

   # Run with webhook to Chatwoot
   ./whatsapp-linux-amd64 rest \
     --port 3000 \
     --basic-auth="admin:secret123" \
     --webhook="http://localhost:3001/webhooks/whatsapp/+1234567890" \
     --webhook-secret="dev_webhook_secret"
   ```

2. **Login to WhatsApp**:
   - Open http://localhost:3000
   - Scan QR code with WhatsApp mobile app
   - Or use pairing code method

3. **Test API Connection**:
   ```bash
   curl -u admin:secret123 http://localhost:3000/app/devices
   ```

### Implementation Checklist

#### Backend Tasks

- [ ] Add `whatsapp_web` to `Channel::Whatsapp::PROVIDERS`
- [ ] Create `Whatsapp::Providers::WhatsappMultideviceService`
  - [ ] Implement `send_message` (text and media)
  - [ ] Implement `send_template` (return nil initially)
  - [ ] Implement `sync_templates` (return empty array)
  - [ ] Implement `validate_provider_config?` (check `/app/devices`)
  - [ ] Implement `api_headers` (Basic Auth)
  - [ ] Implement `media_url` (construct from media_path)
- [ ] Create `Whatsapp::IncomingMessageMultideviceService`
  - [ ] Handle text messages
  - [ ] Handle media messages (image, video, audio, document, sticker)
  - [ ] Handle contact and location messages
  - [ ] Handle reactions
  - [ ] Handle receipts (delivered, read, played)
  - [ ] Handle group events (join, leave, promote, demote)
  - [ ] Handle protocol events (delete, revoke, edit)
- [ ] Update `Webhooks::WhatsappEventsJob` for provider routing
- [ ] Update `Webhooks::WhatsappController` for HMAC signature verification
- [ ] Write RSpec tests (provider service, incoming service, controller)

#### Frontend Tasks

- [ ] Create `WhatsappMultidevice.vue` component
  - [ ] Form fields: Inbox Name, Phone Number, API Base URL, Username, Password
  - [ ] Validation: required fields, E.164 phone format, valid URL
  - [ ] Submit handler with error handling
- [ ] Update `Whatsapp.vue` provider selection
  - [ ] Add "WhatsApp Web" to provider list
  - [ ] Add icon and description
  - [ ] Add routing to WhatsappMultidevice component
- [ ] Add i18n translations in `en/inboxMgmt.json`
- [ ] Write Vitest tests

#### Testing Tasks

- [ ] Unit tests for provider service (85%+ coverage)
- [ ] Unit tests for incoming message service (85%+ coverage)
- [ ] Controller tests for webhook security
- [ ] Frontend component tests
- [ ] Integration tests with mock webhook payloads
- [ ] Manual testing with real Go WhatsApp service

## Key Technical Decisions

### Provider Configuration

The provider stores configuration in the `provider_config` JSONB field:

```ruby
{
  api_base_url: "http://localhost:3000",
  basic_auth_username: "admin",
  basic_auth_password: "secret123",
  webhook_verify_token: "auto_generated_hex_32"  # For HMAC verification
}
```

### Authentication Method

- **API Calls**: HTTP Basic Authentication
- **Webhooks**: HMAC SHA256 signature verification using `X-Hub-Signature-256` header

### Webhook Event Processing

The service sends various event types:

1. **Regular Messages**: Text, media, contacts, locations
2. **Receipts**: `message.ack` events for delivered/read status
3. **Group Events**: `group.participants` events for membership changes
4. **Protocol Events**: Message deletions, revocations, edits

Each event type is handled appropriately in `IncomingMessageMultideviceService`.

### Media Handling

- Media files are stored on the Go WhatsApp service
- Webhook provides `media_path` (e.g., `statics/media/filename.ext`)
- Chatwoot downloads media from: `{api_base_url}/{media_path}`
- Media is cached as attachment in Chatwoot database

### Template Support

Templates are **NOT supported** in initial implementation:
- `send_template` returns nil
- `sync_templates` returns empty array
- Can be added in future enhancement

## Security Considerations

### HMAC Signature Verification

All webhooks must include valid HMAC SHA256 signature:

```ruby
# Webhook header
X-Hub-Signature-256: sha256={hmac_hex}

# Verification
expected = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, raw_payload)
received = signature.sub('sha256=', '')
ActiveSupport::SecurityUtils.secure_compare(expected, received)
```

### Basic Auth Storage

- Credentials stored in encrypted `provider_config` JSONB
- Never exposed in frontend or logs
- Use environment variables in production

### Webhook Secret

- Auto-generated 32-byte hex token
- Must match between Chatwoot and Go WhatsApp service
- Rotatable via provider config update

## Common Pitfalls & Solutions

### Phone Number Format

**Issue**: Phone numbers must include `@s.whatsapp.net` for JID format

**Solution**:
```ruby
def ensure_jid_format(phone_number)
  phone_number.include?('@') ? phone_number : "#{phone_number}@s.whatsapp.net"
end
```

### Media Download Failures

**Issue**: Media files may be unavailable or download may fail

**Solution**:
- Create message without attachment
- Log error with media_path for debugging
- Show placeholder in UI with error message

### Audio Files with MIME Type Parameters

**Issue**: WhatsApp Web service saves audio files with MIME parameters in the filename (e.g., `file.ogg; codecs=opus`), causing 404 errors when downloading

**Root Cause**:
- Go WhatsApp Web stores files with full MIME type in filename: `statics/media/file.ogg; codecs=opus`
- If we sanitize the path before downloading, we get: `statics/media/file.ogg`
- File doesn't exist at sanitized path → 404 Not Found

**Solution**:
- Keep original unsanitized path for downloading from WhatsApp Web service
- Sanitize filename only when creating ActiveStorage attachment
- Implementation in `IncomingMessageWhatsappWebService`:
  ```ruby
  # In extract_media_info: Keep original path
  media_info[:id] = media_data[:media_path] || media_data[:id]

  # In attach_files: Sanitize when saving
  sanitized_filename = sanitize_media_path(original_filename)

  # Helper method
  def sanitize_media_path(media_path)
    media_path.to_s.split(';').first&.strip
  end
  ```

**Result**:
- Download succeeds with original path: `GET /5521995539939/statics/media/file.ogg; codecs=opus`
- Attachment saved with clean name: `file.ogg`
- Audio transcription works correctly (FEAT-003 integration)

### Duplicate Webhooks

**Issue**: Same event may be delivered multiple times

**Solution**:
- Check for existing message by `source_id`
- Update status if already exists
- Use idempotent processing logic

### WhatsApp Not Connected

**Issue**: Service not logged in via QR/pairing code

**Solution**:
- Validate connection during inbox creation (`/app/devices`)
- Return clear error message
- Provide link to service UI for login

### Gateway Connection Refused Errors

**Issue**: Chatwoot fails to process messages with "Connection refused" errors when calling gateway API

**Root Cause**: Gateway service may be restarting due to panics (e.g., profile picture fetch issues)

**Solution**:
- Implement retry logic in Chatwoot API calls
- Make contact info/avatar fetch non-blocking
- Add panic recovery in gateway service
- See [ISSUE-001](./ISSUE-001-message-loss-on-profile-picture-fetch.md) for detailed analysis and fixes

## Testing Strategy

### Unit Tests

- **Provider Service**: Test all public methods with mocked HTTP calls
- **Incoming Service**: Test event processing with various payloads
- **Webhook Controller**: Test signature verification and routing

### Integration Tests

- Mock Go WhatsApp API responses
- Test complete message flow (send → webhook → create)
- Test all event types and edge cases

### End-to-End Tests

- Deploy real Go WhatsApp service
- Login via QR code
- Send/receive actual messages
- Verify media handling
- Test group operations

### Security Tests

- Verify HMAC signature rejection
- Test replay attack prevention
- Validate credential encryption
- Check for sensitive data leakage

## Performance Considerations

### Message Throughput

- Target: 100+ messages/second receive capacity
- Use background job queue for webhook processing
- Optimize database queries for message creation

### Media Processing

- Download media asynchronously
- Set timeout limits (60s for large files)
- Implement retry logic for failed downloads

### Webhook Delivery

- Go WhatsApp service uses exponential backoff
- 5 retry attempts over ~30 seconds
- Chatwoot must respond within 10 seconds

## Monitoring & Observability

### Key Metrics to Track

1. **Inbox Creation Success Rate**: `whatsapp_web_inbox_created{status="success|failure"}`
2. **Message Send Success Rate**: `whatsapp_web_message_sent{status="success|failure"}`
3. **Webhook Processing Time**: `whatsapp_web_webhook_duration_seconds`
4. **Media Download Success Rate**: `whatsapp_web_media_downloaded{status="success|failure"}`
5. **Signature Verification Failures**: `whatsapp_web_signature_invalid_total`

### Logging Strategy

- **INFO**: Successful operations (message sent, webhook processed)
- **WARN**: Non-critical failures (media download retry, unknown event type)
- **ERROR**: Critical failures (signature invalid, API unreachable, send failed)

### Alerting Rules

- Signature verification failures > 10/minute → Security alert
- Message send failures > 20% → Operational alert
- Webhook processing time > 5s → Performance alert
- API connection failures > 5/minute → Service alert

## Future Enhancements

### Phase 2 Features

1. **Template Support**
   - Implement template API if added to Go WhatsApp service
   - Sync and send WhatsApp message templates
   - Template parameter replacement

2. **Advanced Group Operations**
   - Create groups from Chatwoot
   - Manage group settings (name, photo, permissions)
   - Batch participant operations

3. **Interactive Messages**
   - List messages with selectable options
   - Button messages for quick replies
   - Poll creation and result tracking

4. **Enhanced Media Handling**
   - Automatic compression for large files
   - Image editing and cropping
   - Video thumbnail generation

5. **Multi-Device Management**
   - Support multiple WhatsApp numbers per account
   - Device connection status monitoring
   - Automatic reconnection on disconnect

### Technical Debt

- Add retry mechanism for failed API calls
- Implement circuit breaker for unstable connections
- Add request/response caching for performance
- Create admin UI for connection management

## Support Resources

### For Users

- Setup Guide: See [Deployment Guide](./deployment-guide.md)
- Troubleshooting: See [Implementation Story](./implementation-story.md#support--troubleshooting)
- FAQ: Coming soon

### For Developers

- Architecture: See [Provider Pattern Guide](./creating-whatsapp-inbox-provider.md)
- API Reference: See [API Documentation](./openapi.md)
- Webhook Format: See [Webhook Payload Docs](./webhook-payload.md)

### For Support Team

- Common Issues: See Implementation Story
- Error Messages: See Provider Service error handling
- Escalation Path: GitHub Issues → Engineering Team

## Contributing

To contribute to this feature:

1. Read all documentation in this folder
2. Set up development environment (see Quick Start above)
3. Create feature branch from `next`
4. Follow existing provider pattern
5. Write tests (80%+ coverage required)
6. Submit PR with description linking to this story

## Questions & Feedback

- GitHub Discussions: https://github.com/chatwoot/chatwoot/discussions
- Discord: https://discord.gg/chatwoot
- Email: support@chatwoot.com

---

**Feature Status**: Planning / In Development
**Documentation Version**: 1.0
**Last Updated**: 2025-10-05
**Maintained By**: Chatwoot Team
