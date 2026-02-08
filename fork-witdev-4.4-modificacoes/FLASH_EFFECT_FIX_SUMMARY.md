# Flash Effect Fix - Instagram Rich Message Dashboard

## Problem Description

The Instagram Rich Message Dashboard was experiencing a visual "flash effect" where:

1. Messages were initially created as `content_type: "text"` with fallback text
2. The UI would render the text message briefly
3. Then the `Instagram::RichMessageService` would update the message to `content_type: "cards"`
4. The UI would receive the update and switch to rendering rich cards
5. This caused a visible flash from text → rich cards

## Root Cause

The issue was in the message creation flow in `lib/integrations/socialwise/instagram_response_processor.rb`:

```ruby
# OLD CODE - Created text messages first
outgoing_message = conversation.messages.create!(
  content: extract_fallback_text({ 'payload' => payload }),
  message_type: :outgoing,
  account_id: conversation.account_id,
  inbox_id: conversation.inbox_id,
  additional_attributes: { skip_send_reply: true }
)

# Then later, Instagram::RichMessageService would update to cards
message.update_columns(
  content_type: Message.content_types[mapped_result.content_type],
  content_attributes: mapped_result.content_attributes,
  # ...
)
```

This created two separate ActionCable broadcasts:
1. `message.created` with text content
2. `message.updated` with rich cards content

## Solution Implemented

### 1. Enhanced Message Creation Logic

Added new helper methods in `InstagramResponseProcessor`:

- `create_rich_outgoing_message()` - Main entry point that checks feature flag
- `create_rich_message_directly()` - Creates messages directly as rich cards
- `create_text_message()` - Fallback to existing text behavior

### 2. Feature Flag Conditional Logic

```ruby
def create_rich_outgoing_message(conversation, instagram_payload, original_payload)
  account = conversation.account
  rich_dashboard_enabled = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
  
  if rich_dashboard_enabled
    # Create message directly as rich cards (no flash)
    create_rich_message_directly(conversation, instagram_payload, original_payload)
  else
    # Create regular text message (existing behavior)
    create_text_message(conversation, original_payload)
  end
end
```

### 3. Direct Rich Message Creation

```ruby
def create_rich_message_directly(conversation, instagram_payload, original_payload)
  # Use Instagram Renderer Mapper to convert payload
  mapped_result = Messages::InstagramRendererMapper.map(instagram_payload)
  
  # Create message directly with rich content
  message = conversation.messages.create!(
    content: mapped_result.fallback_text,
    content_type: mapped_result.content_type,           # ← Already "cards"
    content_attributes: mapped_result.content_attributes, # ← Rich content
    message_type: :outgoing,
    account_id: conversation.account_id,
    inbox_id: conversation.inbox_id,
    additional_attributes: { skip_send_reply: true }
  )
end
```

### 4. Updated Instagram Rich Message Service

Enhanced `mirror_rich_payload_to_dashboard()` to skip mirroring when message is already rich:

```ruby
def mirror_rich_payload_to_dashboard
  return unless rich_dashboard_enabled?
  
  # Check if message is already in rich format (created directly as cards)
  if message_already_rich?
    Rails.logger.info "Message already created as rich cards, skipping mirroring"
    return
  end
  
  # Only update if message was created as text
  # ... existing update logic
end

def message_already_rich?
  rich_content_types = %w[cards input_select]
  rich_content_types.include?(message.content_type)
end
```

## Result

### Before Fix:
1. `message.created` → UI shows text "Dra. Amanda..."
2. `message.updated` → UI switches to rich cards
3. **Visible flash effect** ❌

### After Fix:
1. `message.created` → UI shows rich cards directly
2. No `message.updated` for content (only for `source_id` after Instagram API response)
3. **No flash effect** ✅

## Files Modified

1. **`lib/integrations/socialwise/instagram_response_processor.rb`**
   - Added `create_rich_outgoing_message()` helper
   - Added `create_rich_message_directly()` method
   - Added `create_text_message()` fallback method
   - Updated all three message creation locations (Generic Template, Button Template, Quick Replies)

2. **`app/services/instagram/rich_message_service.rb`**
   - Enhanced `mirror_rich_payload_to_dashboard()` with rich message detection
   - Added `message_already_rich?()` helper method

## Backward Compatibility

- ✅ Accounts without `SOCIALWISE_RICH_DASHBOARD` feature flag continue using text messages
- ✅ Existing functionality preserved for non-rich accounts
- ✅ No breaking changes to API or database schema
- ✅ All existing tests should continue to pass

## Performance Benefits

- **Reduced database operations**: No unnecessary `update_columns` call when message is created directly as rich
- **Reduced ActionCable broadcasts**: Only one `message.created` event instead of `created` + `updated`
- **Better UX**: Eliminates visual flash effect for smoother user experience

## Testing

The fix can be tested by:

1. Ensuring account has `SOCIALWISE_RICH_DASHBOARD` feature enabled
2. Sending a rich message (Generic Template, Button Template, or Quick Replies)
3. Observing that the message appears directly as rich cards without text flash
4. Checking logs to confirm "Message already created as rich cards, skipping mirroring"

## Logs to Look For

**Success indicators:**
```
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating message directly as rich cards
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created rich message directly with ID: 12345
[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring
```

**Fallback indicators (feature disabled):**
```
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating regular text message
[SOCIALWISE-INSTAGRAM-RICH] === STARTING DASHBOARD MIRRORING ===
```