# Bot Agent Typing API Documentation

## Tổng Quan

Bot agents có thể chủ động gửi typing indicators thông qua API `toggle_typing_status` để tạo trải nghiệm tốt hơn cho người dùng trong quá trình bot "suy nghĩ" để tạo câu trả lời.

## Cấu Hình Bot Access

Bot agents đã được cấu hình để có thể truy cập API `toggle_typing_status` thông qua bot access token.

### Endpoints Được Phép Cho Bot Agents

```ruby
BOT_ACCESSIBLE_ENDPOINTS = {
  'api/v1/accounts/conversations' => %w[
    toggle_status 
    toggle_priority 
    toggle_typing_status  # ✅ Đã thêm cho bot agents
    create 
    update 
    custom_attributes
  ],
  'api/v1/accounts/conversations/messages' => ['create'],
  'api/v1/accounts/conversations/assignments' => ['create']
}
```

## API Usage

### 1. Bật Typing Indicator

```bash
curl -X POST "{{host}}/{{api_version}}/accounts/{{account_id}}/conversations/{{conversation_id}}/toggle_typing_status" \
  -H "api_access_token: YOUR_BOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "typing_status": "on",
    "is_private": false
  }'
```

### 2. Tắt Typing Indicator

```bash
curl -X POST "{{host}}/{{api_version}}/accounts/{{account_id}}/conversations/{{conversation_id}}/toggle_typing_status" \
  -H "api_access_token: YOUR_BOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "typing_status": "off",
    "is_private": false
  }'
```

## Workflow Tối Ưu Cho Bot

### Kịch Bản Sử Dụng

1. **Nhận tin nhắn từ user**
2. **Bật typing indicator ngay lập tức** (để user biết bot đang xử lý)
3. **Gửi request đến AI service** để tạo câu trả lời
4. **Tắt typing indicator** khi đã có câu trả lời
5. **Gửi tin nhắn** cho user

### Code Example (JavaScript)

```javascript
async function handleUserMessage(conversationId, userMessage) {
  try {
    // 1. Bật typing indicator ngay lập tức
    await toggleTyping(conversationId, 'on');
    
    // 2. Gửi request đến AI service (có thể mất 2-5 giây)
    const aiResponse = await callAIService(userMessage);
    
    // 3. Tắt typing indicator
    await toggleTyping(conversationId, 'off');
    
    // 4. Gửi tin nhắn cho user
    await sendMessage(conversationId, aiResponse);
    
  } catch (error) {
    // Đảm bảo tắt typing indicator nếu có lỗi
    await toggleTyping(conversationId, 'off');
    console.error('Error handling message:', error);
  }
}

async function toggleTyping(conversationId, status) {
  const response = await fetch(`${API_BASE}/accounts/${ACCOUNT_ID}/conversations/${conversationId}/toggle_typing_status`, {
    method: 'POST',
    headers: {
      'api_access_token': BOT_ACCESS_TOKEN,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      typing_status: status,
      is_private: false
    })
  });
  
  return response.ok;
}
```

### Code Example (Python)

```python
import requests
import asyncio

async def handle_user_message(conversation_id, user_message):
    try:
        # 1. Bật typing indicator
        await toggle_typing(conversation_id, 'on')
        
        # 2. Gọi AI service
        ai_response = await call_ai_service(user_message)
        
        # 3. Tắt typing indicator
        await toggle_typing(conversation_id, 'off')
        
        # 4. Gửi tin nhắn
        await send_message(conversation_id, ai_response)
        
    except Exception as e:
        # Đảm bảo tắt typing indicator
        await toggle_typing(conversation_id, 'off')
        print(f"Error: {e}")

async def toggle_typing(conversation_id, status):
    url = f"{API_BASE}/accounts/{ACCOUNT_ID}/conversations/{conversation_id}/toggle_typing_status"
    headers = {
        'api_access_token': BOT_ACCESS_TOKEN,
        'Content-Type': 'application/json'
    }
    data = {
        'typing_status': status,
        'is_private': False
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response.status_code == 200
```

## Tính Năng Tự Động

### Platform Integration

Khi bot agent gửi typing events qua API, hệ thống sẽ tự động:

1. **Gửi typing indicator đến WebSocket** cho dashboard users
2. **Gửi typing indicator đến platform** (Facebook/Instagram) nếu conversation thuộc các channel này
3. **Log events** để tracking và debugging

### Supported Platforms

- ✅ **Facebook Messenger** - Sử dụng Facebook Graph API v22
- ✅ **Instagram Direct** - Sử dụng Instagram Graph API v22  
- ✅ **Web Widget** - Qua WebSocket real-time
- ✅ **Dashboard** - Hiển thị typing status cho agents

## Error Handling

### Response Codes

- `200 OK` - Typing indicator đã được gửi thành công
- `401 Unauthorized` - Bot access token không hợp lệ
- `404 Not Found` - Conversation không tồn tại
- `403 Forbidden` - Bot không có quyền truy cập conversation

### Best Practices

1. **Luôn tắt typing indicator** sau khi hoàn thành xử lý
2. **Sử dụng try-catch** để đảm bảo typing indicator được tắt ngay cả khi có lỗi
3. **Không gửi typing quá lâu** (tối đa 30 giây)
4. **Kiểm tra response status** để đảm bảo API call thành công

## Monitoring & Logs

### Log Messages

```
INFO: TypingStatusManager: Bot agent typing ON sent to Channel::FacebookPage - Success: true
INFO: TypingStatusManager: Bot agent typing OFF sent to Channel::Instagram - Success: true
ERROR: TypingStatusManager: Error sending bot agent typing to platform: [error_message]
```

### Metrics Tracking

Hệ thống tự động track:
- Số lượng typing events từ bot agents
- Success/failure rates cho từng platform
- Response times cho typing API calls

## Migration Notes

Nếu bạn đang sử dụng Bot API endpoints cũ (`/api/v1/bot/conversations/:id/typing_on`), bạn có thể tiếp tục sử dụng hoặc chuyển sang API mới để có thêm tính năng WebSocket integration.

### So Sánh APIs

| Feature | Bot API | Toggle API |
|---------|---------|------------|
| Platform typing | ✅ | ✅ |
| WebSocket events | ❌ | ✅ |
| Dashboard integration | ❌ | ✅ |
| is_private support | ❌ | ✅ |

## Support

Nếu có vấn đề với typing functionality, kiểm tra:
1. Bot access token có hợp lệ không
2. Conversation có tồn tại không  
3. Platform tokens (Facebook/Instagram) có hợp lệ không
4. Logs để xem error messages chi tiết
