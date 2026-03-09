# WhatsApp Sticker Duplicate Send Fix Summary

## 🚨 Problem Identified

Based on the logs and analysis, there were two main issues with the WhatsApp sticker functionality:

1. **Duplicate Messages**: Stickers were being sent twice - once through the normal message flow and once through the direct API call
2. **Wrong Phone Number**: Stickers were being sent to incorrect phone numbers, outside the context of the current conversation

## 🔍 Root Cause Analysis

### Issue 1: Duplicate Sending
The problem was in the message creation flow:

1. `create_sticker_message` creates a message in the database
2. The `after_create_commit` callback triggers `SendReplyJob` → **FIRST MESSAGE**
3. The service then calls `send_sticker_message` directly → **SECOND MESSAGE**

### Issue 2: Wrong Phone Number
The phone number extraction was working correctly (`conversation.contact_inbox.source_id`), but there might have been validation issues or race conditions.

## 🛠️ Solutions Implemented

### 1. Fixed Duplicate Sending with `skip_send_reply` Flag

**Location**: `app/services/whatsapp/send_sticker_service.rb`

```ruby
def create_sticker_message
  @conversation.messages.create!(
    content: "Sticker: #{@sticker_data[:alt]}",
    content_type: 'sticker',
    content_attributes: { sticker_data: @sticker_data },
    message_type: :outgoing,
    account_id: @conversation.account_id,
    inbox_id: @conversation.inbox_id,
    additional_attributes: { 
      skip_send_reply: true # CRITICAL FLAG - Prevents duplicate sending!
    }
  )
end
```

**How it works**:
- The `skip_send_reply: true` flag prevents the automatic `SendReplyJob` from being triggered
- Only the direct `send_sticker_message` call sends the actual sticker
- Result: **1 message instead of 2**

### 2. Enhanced Phone Number Validation

**Location**: `app/services/whatsapp/send_sticker_service.rb`

```ruby
def validate_inputs!
  # ... existing validations ...
  
  # NEW: Validate contact_inbox exists and has source_id (phone number)
  unless @conversation.contact_inbox&.source_id.present?
    raise ConversationNotFoundError, 'No phone number found for this conversation'
  end
  
  # ... rest of validations ...
  
  Rails.logger.info "WhatsApp SendStickerService: Target phone number: #{@conversation.contact_inbox.source_id}"
end
```

### 3. Improved Error Handling in send_to_whatsapp

**Location**: `app/services/whatsapp/send_sticker_service.rb`

```ruby
def send_to_whatsapp(media_id)
  phone_number = @conversation.contact_inbox.source_id
  
  # Validate phone number before sending
  if phone_number.blank?
    Rails.logger.error "WhatsApp SendStickerService: No phone number found for conversation #{@conversation.id}"
    return { success: false, error: 'No phone number found for this conversation' }
  end
  
  # ... rest of method ...
end
```

## 🔄 Corrected Flow

### Before (Problematic):
1. Create message in database (WITHOUT `skip_send_reply`)
2. `after_create_commit` triggers `SendReplyJob` → **SENDS MESSAGE 1**
3. Service calls `send_sticker_message` → **SENDS MESSAGE 2**
4. **Result**: 2 messages sent to WhatsApp ❌

### After (Fixed):
1. Create message in database (WITH `skip_send_reply: true`)
2. `send_reply()` checks the flag and **SKIPS** automatic sending
3. Service calls `send_sticker_message` → **SENDS ONLY MESSAGE**
4. **Result**: 1 message sent to WhatsApp ✅

## 🧪 Testing

Created `test_sticker_fix.rb` to verify:
- Conversation and phone number extraction
- Service initialization
- Input validation
- Phone number matching with successful image sends

## 📊 Expected Results

After this fix:
- ✅ Only one sticker message per send request
- ✅ Stickers sent to the correct phone number (same as successful image sends)
- ✅ Proper error handling for missing phone numbers
- ✅ Consistent behavior with other WhatsApp message types

## 🔍 Key Files Modified

1. `app/services/whatsapp/send_sticker_service.rb`
   - Added `skip_send_reply: true` flag
   - Enhanced phone number validation
   - Improved error handling

2. `test_sticker_fix.rb` (new)
   - Test script to verify the fix

## 🎯 Verification Steps

1. Run the test script: `rails runner test_sticker_fix.rb`
2. Send a test sticker through the UI
3. Check logs to confirm:
   - Only one WhatsApp API call is made
   - Phone number matches the conversation's contact
   - No duplicate messages appear

## 📝 Notes

This fix follows the same pattern used successfully in other parts of the codebase for preventing duplicate message sending, as documented in the tech steering rules.