# Ad Source Metadata Tracking

## Overview

This feature adds support for capturing and displaying advertising source metadata for conversations originating from Instagram and WhatsApp ads. When a user contacts your business through an ad, Chatwoot now captures campaign information, ad IDs, and other referral data to enable marketing attribution and ROI tracking.

## Features

- **Automatic capture** of ad source metadata from WhatsApp and Instagram webhooks
- **Visual display** of ad campaign information in the conversation sidebar
- **Persistent storage** in conversation `additional_attributes`
- **API exposure** of ad metadata through existing conversation endpoints
- **Indexed database** queries for efficient filtering and analytics

## Supported Platforms

### WhatsApp
- Ad source type
- Ad source ID
- Source URL
- Ad headline and body
- Media type and URL
- Click-to-WhatsApp (CTWA) click ID
- Context and referral information

### Instagram
- Ad source type
- Ad reference
- Referer URI
- Ad ID
- Ad title
- Photo/Video URL
- Product ID
- Guest user status

## Implementation Details

### Backend Changes

#### 1. WhatsApp Service (`app/services/whatsapp/incoming_message_service_helpers.rb`)
The `extract_ad_source_metadata` method extracts referral data from webhook payloads:

```ruby
def extract_ad_source_metadata
  message = @processed_params[:messages]&.first
  return {} if message.blank?

  metadata = {}

  # Extract referral data from WhatsApp ads
  if message[:referral].present?
    referral = message[:referral]
    metadata[:ad_source] = 'whatsapp_ad'
    metadata[:ad_source_id] = referral[:source_id]
    metadata[:ad_source_type] = referral[:source_type]
    # ... additional fields
  end

  metadata.compact
end
```

#### 2. Instagram Service (`app/builders/messages/instagram/base_message_builder.rb`)
The `extract_instagram_ad_metadata` method captures ad data from both `referral` and `postback.referral` fields:

```ruby
def extract_instagram_ad_metadata
  metadata = {}
  
  if @messaging[:referral].present?
    referral = @messaging[:referral]
    metadata[:ad_source] = 'instagram_ad'
    metadata[:ad_source_id] = referral[:source]
    # ... additional fields
  end

  metadata.compact
end
```

#### 3. Database Migration
A GIN index is added to the `conversations.additional_attributes` JSONB column for efficient querying:

```ruby
add_index :conversations, :additional_attributes,
          using: :gin,
          name: 'index_conversations_on_additional_attributes_gin',
          algorithm: :concurrently
```

### Frontend Changes

#### 1. Ad Source Info Component (`app/javascript/dashboard/routes/dashboard/conversation/AdSourceInfo.vue`)
A new Vue component displays ad metadata in a user-friendly format with:
- Platform icon (WhatsApp/Instagram)
- Ad source type
- Campaign reference
- Ad ID and title
- Source URL (clickable)

#### 2. Contact Panel Integration
The `AdSourceInfo` component is integrated into the conversation sidebar's "Conversation Info" section, appearing automatically when ad metadata is present.

#### 3. Internationalization
New translation keys added in `app/javascript/dashboard/i18n/locale/en/conversation.json`:

```json
"AD_SOURCE": {
  "SOURCE_TYPE": "Source Type",
  "AD_ID": "Ad ID",
  "AD_TITLE": "Ad Title",
  // ... additional labels
}
```

## Data Structure

### Conversation Additional Attributes

Ad metadata is stored in the `conversations.additional_attributes` JSONB field:

```json
{
  "ad_source": "whatsapp_ad",
  "ad_source_id": "ad_campaign_123",
  "ad_source_type": "ad",
  "ad_source_url": "https://example.com/ad",
  "ad_headline": "Amazing Product!",
  "ad_body": "Get 50% off today",
  "ad_media_type": "image",
  "ad_media_url": "https://example.com/image.jpg",
  "ad_ctwa_clid": "click_id_abc123",
  "ad_id": "ad_456",
  "ad_title": "Summer Sale",
  "ad_ref": "campaign_ref",
  "product_id": "product_789"
}
```

## Usage

### Viewing Ad Source Information

1. Open any conversation that originated from an ad
2. Navigate to the conversation sidebar
3. Expand the "Conversation Info" section
4. Ad source information will be displayed at the top if available

### API Access

Ad metadata is included in conversation API responses through the `additional_attributes` field:

```
GET /api/v1/accounts/{accountId}/conversations/{conversationId}
```

Response includes:
```json
{
  "id": 123,
  "additional_attributes": {
    "ad_source": "instagram_ad",
    "ad_id": "ad_456",
    // ... other ad fields
  },
  // ... other conversation fields
}
```

### Analytics and Filtering

You can query conversations by ad source using PostgreSQL JSONB operators:

```sql
-- Find all conversations from WhatsApp ads
SELECT * FROM conversations 
WHERE additional_attributes->>'ad_source' = 'whatsapp_ad';

-- Find conversations from specific campaign
SELECT * FROM conversations 
WHERE additional_attributes->>'ad_ref' = 'campaign_123';

-- Count conversations by ad source
SELECT 
  additional_attributes->>'ad_source' as source,
  COUNT(*) as conversation_count
FROM conversations
WHERE additional_attributes ? 'ad_source'
GROUP BY additional_attributes->>'ad_source';
```

## Testing

Comprehensive RSpec tests have been added for both platforms:

### WhatsApp Tests
- `spec/services/whatsapp/incoming_message_service_spec.rb`
  - Extraction of referral data
  - Context data extraction
  - Preservation of existing attributes
  - Update behavior for existing conversations

### Instagram Tests
- `spec/builders/messages/instagram/message_builder_spec.rb`
  - Referral data extraction
  - Postback referral extraction
  - Conversation attribute updates
  - Data preservation logic

## Meta API References

### WhatsApp Business API
- [Set up ads that click to WhatsApp](https://developers.facebook.com/docs/whatsapp/business-management-api/guides/set-up-ads)
- [WhatsApp Cloud API - Messages](https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/components#messages-object)

### Instagram Messaging API
- [Instagram Referrals](https://developers.facebook.com/docs/messenger-platform/instagram/features/referral)
- [Instagram Ice Breakers](https://developers.facebook.com/docs/instagram-api/guides/messaging/ice-breakers)

## Migration Guide

To enable this feature in your Chatwoot instance:

1. **Run the migration:**
   ```bash
   bundle exec rails db:migrate
   ```

2. **Restart your application:**
   ```bash
   # Using systemd
   sudo systemctl restart chatwoot-web
   sudo systemctl restart chatwoot-worker
   
   # Using Docker
   docker-compose restart
   ```

3. **Verify the feature:**
   - Send a test message from a WhatsApp or Instagram ad
   - Check the conversation sidebar for ad source information
   - Verify database records contain ad metadata

## Limitations

- Ad metadata is only captured for **new conversations** or the **first message** from an ad
- Existing conversations with ad data will not be overwritten
- Not all ad campaigns include referral parameters (depends on Meta/Facebook ad setup)
- Guest users on Instagram may have limited metadata available

## Troubleshooting

### Ad metadata not appearing

1. **Check webhook payload:** Ensure Meta is sending `referral` data in webhooks
2. **Verify ad configuration:** Ad campaigns must be properly configured in Meta Ads Manager
3. **Check logs:** Search for `extract_ad_source_metadata` in application logs
4. **Database verification:** Query `conversations.additional_attributes` to check if data is being stored

### Performance considerations

- The GIN index significantly improves JSONB query performance
- For high-traffic instances, consider periodic cleanup of old conversation metadata
- Monitor index usage with `pg_stat_user_indexes`

## Future Enhancements

Potential improvements for this feature:

- [ ] Custom reports showing conversation volume by ad campaign
- [ ] Integration with analytics platforms (Google Analytics, Mixpanel)
- [ ] Ad performance dashboard within Chatwoot
- [ ] Automated tagging based on ad source
- [ ] Export ad attribution data to CSV
- [ ] Integration with Facebook Ads Manager for ROI calculation

## Contributing

When contributing improvements to this feature, please:

1. Add tests for new ad metadata fields
2. Update this documentation
3. Follow the existing naming conventions for metadata fields
4. Consider backward compatibility with existing data

## Support

For issues or questions about this feature:
- Check the [Chatwoot Documentation](https://www.chatwoot.com/docs)
- Review Meta's [WhatsApp](https://developers.facebook.com/docs/whatsapp) and [Instagram](https://developers.facebook.com/docs/instagram-api) API documentation
- Open an issue on the Chatwoot GitHub repository
