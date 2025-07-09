# Human Agent Configuration - Facebook & Instagram

## Tổng quan

Tính năng Human Agent cho phép bypass giới hạn 24 giờ của Facebook Messenger và Instagram, cho phép gửi tin nhắn bất cứ lúc nào mà không bị hạn chế bởi cửa sổ thời gian.

## Yêu cầu Facebook App

### 1. Permissions cần thiết:
- `pages_messaging` - Bắt buộc cho human agent
- `pages_manage_metadata` - Quản lý page metadata
- `instagram_basic` - Cho Instagram (nếu sử dụng)
- `instagram_manage_messages` - Quản lý tin nhắn Instagram

### 2. App Review từ Facebook:
- Submit app để review với use case "Human Agent"
- Cung cấp video demo và documentation
- Giải thích rõ ràng việc sử dụng human agent tag

## Cấu hình trong Chatwoot

### 1. Super Admin Settings

Truy cập Super Admin panel và bật các cài đặt sau:

```
ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT = true
ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT = true
```

### 2. Kiểm tra cấu hình qua Rails Console

```ruby
# Kiểm tra Facebook Messenger
fb_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
puts "Facebook Human Agent: #{fb_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']}"

# Kiểm tra Instagram
ig_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
puts "Instagram Human Agent: #{ig_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']}"
```

## API Testing

### 1. Test Human Agent Configuration

**POST** `/api/v1/accounts/{account_id}/conversations/{conversation_id}/test_human_agent`

```bash
curl -X POST \
  "https://your-domain.com/api/v1/accounts/1/conversations/123/test_human_agent" \
  -H "api_access_token: YOUR_BOT_TOKEN" \
  -H "Content-Type: application/json"
```

### 2. Response Example

```json
{
  "success": true,
  "results": {
    "global_config": {
      "facebook_messenger": {
        "enabled": true,
        "raw_value": true,
        "config_exists": true
      },
      "instagram": {
        "enabled": true,
        "raw_value": true,
        "config_exists": true
      },
      "current_channel": "Channel::FacebookPage",
      "current_channel_enabled": true
    },
    "message_test": {
      "success": true,
      "messaging_type": "MESSAGE_TAG",
      "tag": "HUMAN_AGENT",
      "human_agent_detected": true
    },
    "permissions": {
      "success": true,
      "has_pages_messaging": true,
      "permission_status": "granted",
      "all_permissions": [
        "pages_messaging: granted",
        "pages_manage_metadata: granted"
      ]
    }
  }
}
```

## Meta API Implementation

### 1. Facebook Messenger

```ruby
# app/services/facebook/send_on_facebook_service.rb
def determine_messaging_params
  if human_agent_enabled?
    return { messaging_type: 'MESSAGE_TAG', tag: 'HUMAN_AGENT' }
  end
  
  # Fallback to normal 24h window logic
  # ...
end
```

### 2. Instagram Direct

```ruby
# app/services/instagram/send_on_instagram_service.rb
def merge_human_agent_tag(params)
  return params unless human_agent_enabled?
  
  params[:messaging_type] = 'MESSAGE_TAG'
  params[:tag] = 'HUMAN_AGENT'
  params
end
```

### 3. Instagram Messenger (via Facebook)

```ruby
# app/services/instagram/messenger/send_on_instagram_service.rb
def merge_human_agent_tag(params)
  global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
  return params unless global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']
  
  params[:messaging_type] = 'MESSAGE_TAG'
  params[:tag] = 'HUMAN_AGENT'
  params
end
```

## Troubleshooting

### 1. Lỗi 24h Window vẫn xuất hiện

**Nguyên nhân:**
- Human agent chưa được bật trong Super Admin
- Facebook app chưa được approve cho human agent
- Thiếu permissions cần thiết

**Giải pháp:**
```bash
# Kiểm tra cấu hình
node examples/human_agent_demo.js CONVERSATION_ID

# Hoặc qua API
curl -X POST "https://your-domain.com/api/v1/accounts/1/conversations/123/test_human_agent" \
  -H "api_access_token: YOUR_TOKEN"
```

### 2. Permissions bị từ chối

**Kiểm tra:**
```bash
# Test permissions
curl "https://graph.facebook.com/v22.0/me/permissions?access_token=YOUR_PAGE_TOKEN"
```

**Cần có:**
- `pages_messaging: granted`
- `pages_manage_metadata: granted`

### 3. App chưa được approve

**Các bước:**
1. Truy cập Facebook App Dashboard
2. Vào App Review
3. Submit request cho "Human Agent" feature
4. Cung cấp documentation và video demo

## Best Practices

### 1. Logging và Monitoring

```ruby
# Thêm vào service
Rails.logger.info "Human agent enabled: #{human_agent_enabled?}"
Rails.logger.info "Using messaging_type: #{messaging_params[:messaging_type]}, tag: #{messaging_params[:tag]}"
```

### 2. Error Handling

```ruby
begin
  send_message_to_facebook(params)
rescue Facebook::Messenger::FacebookError => e
  if e.message.include?('24')
    Rails.logger.error "24h window error - check human agent configuration"
  end
  raise e
end
```

### 3. Testing Strategy

1. **Development:** Test với conversation cũ (>24h)
2. **Staging:** Verify với real Facebook pages
3. **Production:** Monitor logs cho 24h errors

## Code Examples

### JavaScript/Node.js

```javascript
const { testHumanAgent, sendTestMessage } = require('./examples/human_agent_demo');

// Test configuration
const results = await testHumanAgent(conversationId);

// Send test message
const message = await sendTestMessage(conversationId, 'Test human agent message');
```

### Python

```python
import requests

def test_human_agent(conversation_id):
    url = f"{API_BASE}/accounts/{ACCOUNT_ID}/conversations/{conversation_id}/test_human_agent"
    headers = {
        'api_access_token': BOT_TOKEN,
        'Content-Type': 'application/json'
    }
    
    response = requests.post(url, headers=headers)
    return response.json()
```

## Monitoring

### 1. Logs để theo dõi

```bash
# Xem logs human agent
tail -f log/production.log | grep "Human agent"

# Xem logs 24h errors
tail -f log/production.log | grep "24"
```

### 2. Metrics quan trọng

- Tỷ lệ tin nhắn thành công vs failed
- Số lượng 24h window errors
- Human agent tag usage

## Support

Nếu gặp vấn đề:

1. Chạy test endpoint để kiểm tra cấu hình
2. Kiểm tra Facebook app permissions
3. Verify app review status cho human agent
4. Check logs để xem lỗi chi tiết
