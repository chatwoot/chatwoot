We send survey links when agent/contact resolve the conversation, We show a UI template based on the content type (input_csat) in the web widget channel. For other channels, we directly send survey links in the message itself. The issue is that both agents and contacts can see the URL. While it's fine for contacts to see the URL, it's problematic for agents since they could potentially open the link and rate the survey themselves—which would harm business integrity. But we cant conditionally render URL since we are sending the message to different channels.

## There are two solutions to this issue.

### Solution 1: Store survey URL in content_attributes

Store survey URL in `content_attributes['survey_url']` instead of embedding in content.

**Changes Made**:

1. **Modified CSAT template service** in `app/services/message_templates/template/csat_survey.rb`:

```ruby
def content_attributes
  attributes = {
    display_type: csat_config['display_type'] || 'emoji'
  }

  # Store survey URL separately for non-web widget channels
  unless conversation.inbox.web_widget?
    survey_url = "#{ENV.fetch('FRONTEND_URL', nil)}/survey/responses/#{conversation.uuid}"
    attributes['survey_url'] = survey_url
  end

  attributes
end
```

2. **Enhanced message model** in `app/models/message.rb`:

```ruby
def content
  # For non-web widget channels, check if survey_url exists in content_attributes
  survey_url = content_attributes['survey_url']
  if survey_url.present?
    return self[:content]  # Return base content without URL
  end
  # ... existing logic
end

def content_for_channel
  # Method to get content with survey URL for external channel delivery
  return content unless input_csat? && !inbox.web_widget?

  survey_url = content_attributes['survey_url']
  if survey_url.present?
    return "#{self[:content]} #{survey_url}"
  end

  content
end
```

The problem with this approach is we need to update all channel services (WhatsApp, Telegram, SMS, etc.) to use `content_for_channel` instead of `content` for external delivery.

### Solution 2: Frontend - URL Stripping

Strip survey URLs from display for template messages with `content_type: input_csat`
