# CSAT Surveys via WhatsApp Message Templates

## Overview

To ensure successful delivery of CSAT (Customer Satisfaction) surveys via WhatsApp, particularly after the 24-hour customer interaction window, messages must be sent using approved WhatsApp message templates. This spec outlines support for using templates, including automation and service integration.

## Problem

Messages sent after 24 hours without an approved template result in delivery failures. Currently, CSAT surveys are completely disabled for WhatsApp channels after the 24-hour messaging window expires.

## Solution

Support free-form content input and create WhatsApp message templates automatically in the background. Users configure their CSAT message through the existing UI, and the system handles template creation and approval workflow via WhatsApp Business API.

**Key Design Decisions:**
- Templates cannot be edited once submitted to WhatsApp - editing requires deleting the old template and creating a new one
- Template lifecycle is managed automatically - new templates overwrite previous ones
- **Template Priority**: Approved templates are always preferred over regular CSAT messages, regardless of messaging window
- Fallback to regular CSAT only when templates are unavailable and within messaging window

## Data Storage

Template information is stored in the channel's `csat_config` JSONB field:

```json
{
  "message": "Hello! Can you please take this quick survey and provide us with your feedback.",
  "display_type": "emoji",
  "survey_rules": { ... },
  "template": {
    "name": "customer_satisfaction_survey",
    "template_id": "123456789",
    "created_at": "2024-01-01T00:00:00Z",
    "language": "en"
  }
}
```

**Template Naming:**
- **Hardcoded template name**: `customer_satisfaction_survey`
- **Single template per channel**: No multiple templates support
- **Language handling**: Deferred to future implementation

**Note:** Template status is checked in real-time via API calls, not stored in the database.

## Template Structure

Template uses conversation UUID as parameter:
- **Message**: User-configured message content
- **Button URL**: `{{base_url}}/survey/responses/{{1}}` where `{{1}}` is the conversation UUID
- **Button Text**: User-configured button text (default: "Please rate us")

#### Template Creation API

Send a POST request to the WhatsApp Business Account > Message Templates endpoint to create a template.

Request Syntax

POST /<WHATSAPP_BUSINESS_ACCOUNT_ID>/message_templates

Post Body

{
  "name": "customer_satisfaction_survey",
  "category": "MARKETING",
  "language": "<LANGUAGE>",
  "components": [<COMPONENTS>]
}

```
curl --location 'https://graph.facebook.com/v22.0/{{business_account_id}}/message_templates' \
--header 'Content-Type: application/json' \
--data '{
    "name": "customer_satisfaction_survey",
    "language": "en",
    "category": "MARKETING",
    "components": [
        {
            "type": "BODY",
            "text": "Hello! Can you please take this quick survey and provide us with your feedback."
        },
        {
            "type": "BUTTONS",
            "buttons": [
                {
                    "type": "URL",
                    "text": "Please rate us",
                    "url": "{{base_url}}/survey/responses/{{1}}",
                    "example": [
                        "12345"
                    ]
                }
            ]
        }
    ]
}'
```

## Service Integration

### CsatSurveyService Modifications

Extend `app/services/csat_survey_service.rb` to handle WhatsApp templates:

1. **Template Check**: Check if template exists in `csat_config` and verify status via real-time API call
2. **Template Priority Logic**: 
   - If template exists and approved: Always send template (regardless of messaging window)
   - If no template or not approved: Fall back to regular CSAT within messaging window
   - If outside window and no approved template: Create activity message
3. **Survey Rules**: Apply existing label-based survey rules before sending

### WhatsApp Provider Integration

Modify `app/services/whatsapp/send_on_whatsapp_service.rb` to support CSAT templates:
- Add CSAT template sending capability
- Use conversation UUID as template parameter
- Handle template-specific error cases

### Template Management

**Creation Workflow:**
1. User updates CSAT configuration in settings
2. System creates template via WhatsApp Business API
3. Template info stored in `csat_config` (without status)
4. Old templates are automatically replaced

**Send Survey Logic:**
1. Conversation is resolved
2. Check existing survey rules (labels, etc.)
3. Check if template exists and get status via API call
4. **Template Priority:**
   - If template approved: Send template (regardless of messaging window)
   - If no template or not approved:
     - Within messaging window: Send regular CSAT message
     - Outside messaging window: Create activity message

## Error Handling & Fallback

**Template Creation Failures:**
- Display error message in frontend
- Log error details for debugging
- Continue using regular CSAT within messaging window

**Template Sending Failures:**
- Log failure reason
- Create activity message indicating survey couldn't be sent
- Track failure metrics for monitoring

**Fallback Strategy:**
- **Template Priority**: Always prefer approved templates over regular CSAT messages
- **No Template Available**: 
  - Within messaging window: Send regular CSAT message
  - Outside messaging window: Create activity message

## Implementation Notes

**Scope:**
- WhatsApp Cloud API channels only (primary focus)
- 360Dialog provider is deprecated and not supported
- Future extension to other WhatsApp providers like twilio can be considered

**Provider Support:**
- Implement in `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- Use existing template management methods

## Template Status Checking

**Real-time Status API:**

Check template status before sending surveys:

```bash
curl --location 'https://graph.facebook.com/v20.0/{{business_account_id}}/message_templates?name={{template_name}}&access_token={{access_token}}'
```

Example:
```bash
curl --location 'https://graph.facebook.com/v20.0/1189403312549467/message_templates?name=customer_satisfaction_survey&access_token={{access_token}}'
```

**Response Format:**
```json
{
  "data": [
    {
      "name": "customer_satisfaction_survey",
      "status": "APPROVED|PENDING|REJECTED|DISABLED",
      "id": "123456789",
      "language": "en",
      "category": "MARKETING"
    }
  ]
}
```

**Implementation Points:**

1. **Frontend Configuration Page**: Check template status when user visits CSAT settings to show approval status
2. **Before Survey Sending**: Real-time API call to verify template is approved - if approved, always use template
3. **Caching Strategy**: Consider short-term caching (5-10 minutes) to avoid excessive API calls during high-volume periods
4. **Template Priority**: Approved templates bypass messaging window restrictions and are always sent

**Analytics:**
- Template usage tracking not included in initial implementation
- Regular CSAT analytics remain unchanged
- Can be added in future iterations

**Enterprise Compatibility:**
- No specific enterprise overrides required
- Standard CSAT enterprise policies apply