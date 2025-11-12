# Epic 14: Messaging Integrations - Part 1 (Meta)

## Overview
- **Duration**: 2 weeks
- **Complexity**: Very High
- **Dependencies**: Epic 04 (Channel models), Epic 10 (Webhooks)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (each integration independent)

## Scope: 3 Complex Integrations

### 1. Facebook Messenger (Week 1)
- **API Client**: Graph API integration
- **Message Send/Receive**: Text, attachments, templates
- **Webhook Handling**: Messages, postbacks, reactions
- **Media**: Images, videos, files
- **Message Templates**: Structured messages
- **Delivery Reports**: Message status tracking
- **Error Handling**: API errors, rate limits
- **Rate Limiting**: Respect Meta rate limits

### 2. Instagram (Week 1-2)
- **API Client**: Graph API integration
- **Message Send/Receive**: Direct messages
- **Webhook Handling**: Messages, story replies
- **Story Replies**: Handle story mentions
- **Media Messages**: Images, videos
- **Error Handling**: API errors
- **Rate Limiting**: Meta rate limits

### 3. WhatsApp Business API (Week 2)
- **API Client**: Business API / Cloud API
- **Message Send/Receive**: Text, media, templates
- **Webhook Handling**: Messages, status updates
- **Template Messages**: Pre-approved templates
- **Media Messages**: Images, documents, audio, video
- **Interactive Messages**: Buttons, lists
- **Delivery Reports**: Sent, delivered, read
- **Error Handling**: Complex error codes
- **Rate Limiting**: Strict limits
- **Phone Number Validation**: WhatsApp-specific validation

## Why These Together
All three are Meta (Facebook) APIs with similar patterns and authentication

## Parallel Strategy
- **Team A**: Facebook Messenger (full focus, Week 1)
- **Team B**: Instagram (full focus, Week 1)
- **Team C**: WhatsApp (full focus, Week 2)

## Critical Requirements

### Security
- Webhook signature verification (all 3)
- Secure token storage
- API credentials encryption

### Reliability
- Retry logic for failed sends
- Idempotency for webhook processing
- Message deduplication

### Performance
- Async message processing
- Webhook response < 20 seconds (Meta requirement)
- Queue-based architecture

## Integration Pattern

```typescript
// Example: Facebook Service
@Injectable()
export class FacebookService {
  constructor(
    private httpService: HttpService,
    private channelRepository: Repository<ChannelFacebookPage>,
  ) {}

  async sendMessage(channelId: string, recipientId: string, message: string) {
    const channel = await this.channelRepository.findOne(channelId);
    const response = await this.httpService.post(
      `https://graph.facebook.com/v18.0/me/messages`,
      {
        recipient: { id: recipientId },
        message: { text: message },
      },
      {
        headers: {
          Authorization: `Bearer ${channel.pageAccessToken}`,
        },
      }
    );
    return response.data;
  }

  async handleWebhook(payload: FacebookWebhookPayload) {
    // Verify signature
    // Process message
    // Create conversation/message in DB
  }

  verifyWebhookSignature(signature: string, payload: string): boolean {
    // HMAC SHA256 verification
  }
}
```

## Testing Strategy
- Unit tests for each service method
- Integration tests with Meta APIs (test accounts)
- Webhook payload validation tests
- Mock Meta API responses for CI

## Estimated Time
- Facebook: 60 hours
- Instagram: 50 hours
- WhatsApp: 70 hours
- **Total**: 180 hours / 3 engineers ≈ 2 weeks

## Risk: 🔴 HIGH
- Complex APIs with frequent changes
- Rate limiting can cause issues
- Webhook verification critical

---

**Status**: 🟡 Ready (after Epic 04, 10)
**Rails Files**: `app/services/facebook/`, `app/services/instagram/`, `app/services/whatsapp/`
