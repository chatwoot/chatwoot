# Typing Indicators API - Tối ưu cho Facebook/Instagram

## Tổng quan

API Typing Indicators đã được tối ưu để hoạt động chính xác với Facebook Messenger và Instagram Direct Messages theo Facebook API v22. Loại bỏ các logic phức tạp và delay không cần thiết.

## Endpoints

### 1. Toggle Typing Status

**POST** `/api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_typing_status`

Bật/tắt typing indicator cho conversation.

#### Headers
```
api_access_token: YOUR_BOT_ACCESS_TOKEN
Content-Type: application/json
```

#### Request Body
```json
{
  "typing_status": "on",  // "on" hoặc "off"
  "is_private": false     // false cho public typing
}
```

#### Response
```
Status: 200 OK
```

### 2. Test Typing Indicators

**POST** `/api/v1/accounts/{account_id}/conversations/{conversation_id}/test_typing_indicators`

Test tất cả typing indicators cho conversation (mark_seen, typing_on, typing_off).

#### Headers
```
api_access_token: YOUR_BOT_ACCESS_TOKEN
Content-Type: application/json
```

#### Response
```json
{
  "success": true,
  "results": {
    "facebook": {
      "mark_seen": true,
      "typing_on": true,
      "typing_off": true
    }
  },
  "conversation_id": 123,
  "channel_type": "Channel::FacebookPage",
  "message": "Typing indicator test completed. Check mobile device and logs for results."
}
```

## Cách sử dụng

### 1. Bật typing indicator khi bot bắt đầu xử lý

```javascript
// Bật typing indicator
await toggleTyping(conversationId, 'on');

// Xử lý logic bot của bạn ở đây
await processUserMessage();

// Tắt typing indicator trước khi gửi response
await toggleTyping(conversationId, 'off');
```

### 2. Test typing indicators

```javascript
// Test tất cả typing indicators
const testResults = await testTypingIndicators(conversationId);
console.log('Test results:', testResults);
```

## Cấu hình Facebook API

### Sender Actions được hỗ trợ:
- `typing_on` - Hiển thị typing indicator
- `typing_off` - Ẩn typing indicator  
- `mark_seen` - Đánh dấu tin nhắn đã xem

### Cấu hình API chính xác:
```ruby
# Facebook API v22 endpoint
POST https://graph.facebook.com/v22.0/me/messages

# Request body
{
  "recipient": { "id": "USER_ID" },
  "sender_action": "typing_on"  # lowercase
}
```

## Lưu ý quan trọng

### ✅ Đã tối ưu:
- Loại bỏ retry logic phức tạp
- Loại bỏ sleep delays không cần thiết
- Sử dụng lowercase sender_action theo Facebook API
- Loại bỏ messaging_type không cần thiết
- Code đơn giản và hiệu quả

### ❌ Tránh:
- Gửi typing_on mà không tắt typing_off
- Gửi typing liên tục (rate limiting)
- Sử dụng uppercase sender_action
- Thêm messaging_type không cần thiết

### 🔧 Troubleshooting:

1. **Typing không hoạt động trên mobile:**
   - Đảm bảo sử dụng lowercase sender_action
   - Kiểm tra Facebook page access token hợp lệ

2. **Rate limiting:**
   - Không gửi typing quá thường xuyên
   - Sử dụng typing_off sau khi hoàn thành

3. **Token errors:**
   - Kiểm tra page access token
   - Đảm bảo bot có quyền gửi tin nhắn

## Code Examples

### Node.js/JavaScript
```javascript
const axios = require('axios');

const CONFIG = {
  API_BASE: 'https://your-chatwoot-domain.com/api/v1',
  ACCOUNT_ID: 'your-account-id',
  BOT_ACCESS_TOKEN: 'your-bot-access-token'
};

async function toggleTyping(conversationId, status) {
  try {
    await axios.post(
      `${CONFIG.API_BASE}/accounts/${CONFIG.ACCOUNT_ID}/conversations/${conversationId}/toggle_typing_status`,
      {
        typing_status: status,
        is_private: false
      },
      {
        headers: {
          'api_access_token': CONFIG.BOT_ACCESS_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );
    return true;
  } catch (error) {
    console.error(`Error sending typing ${status}:`, error.message);
    return false;
  }
}
```

### Python
```python
import requests

def toggle_typing(conversation_id, status):
    url = f"{API_BASE}/accounts/{ACCOUNT_ID}/conversations/{conversation_id}/toggle_typing_status"
    
    headers = {
        'api_access_token': BOT_ACCESS_TOKEN,
        'Content-Type': 'application/json'
    }
    
    data = {
        'typing_status': status,
        'is_private': False
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error sending typing {status}: {e}")
        return False
```

## Monitoring

Kiểm tra logs để theo dõi typing indicators:

```bash
# Xem logs typing indicators
tail -f log/production.log | grep "TypingIndicatorService"

# Xem logs test results
tail -f log/production.log | grep "TypingIndicatorTestService"
```

## Support

Nếu gặp vấn đề với typing indicators:

1. Chạy test endpoint để kiểm tra
2. Kiểm tra logs để xem lỗi chi tiết
3. Đảm bảo Facebook page access token hợp lệ
4. Kiểm tra conversation có contact và source_id hợp lệ
