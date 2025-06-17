# Hướng dẫn Typing Indicator API v22 cho Facebook và Instagram

## Tổng quan

Dự án đã được cập nhật để sử dụng Facebook Graph API v22 và Instagram API v22 mới nhất với các cải tiến cho mobile compatibility.

## Các thay đổi chính

### 1. Facebook Typing Indicator Service
- **File**: `app/services/facebook/typing_indicator_service.rb`
- **Cải tiến**:
  - Sử dụng API v22 với sender_action uppercase (TYPING_ON, TYPING_OFF, MARK_SEEN)
  - Tăng retry logic từ 3 lên 5 lần cho mobile compatibility
  - Tăng thời gian chờ giữa mark_seen và typing_on từ 0.5s lên 1.0s
  - Cải thiện error logging với backtrace

### 2. Instagram Typing Indicator Service (MỚI)
- **File**: `app/services/instagram/typing_indicator_service.rb`
- **Tính năng**:
  - Service hoàn toàn mới cho Instagram typing indicators
  - Sử dụng Instagram Graph API v22
  - Logic tương tự Facebook nhưng tối ưu cho Instagram
  - Hỗ trợ mark_seen_and_typing cho mobile compatibility

### 3. Bot Typing Service
- **File**: `app/services/bot/typing_service.rb`
- **Cập nhật**:
  - Thêm hỗ trợ Instagram typing indicators
  - Các method mới: `enable_instagram_typing`, `disable_instagram_typing`, `mark_instagram_seen`

### 4. Channel Listener
- **File**: `app/listeners/channel_listener.rb`
- **Cải tiến**:
  - Hỗ trợ cả Facebook và Instagram channels
  - Sử dụng `mark_seen_and_typing` method tối ưu cho mobile
  - Cải thiện error handling và logging

### 5. API Version Configuration
- **Files**: 
  - `config/installation_config.yml`: FACEBOOK_API_VERSION và INSTAGRAM_API_VERSION = v22.0
  - `app/controllers/dashboard_controller.rb`: Default Facebook API version = v22.0

## API Endpoints

### 1. Bot API (Tối ưu cho chatbot)
```
POST /api/v1/bot/conversations/:id/typing_on
POST /api/v1/bot/conversations/:id/typing_off  
POST /api/v1/bot/conversations/:id/mark_seen
```

### 2. Conversation API (Cho dashboard)
```
POST /api/v1/accounts/:account_id/conversations/:id/toggle_typing_status
POST /api/v1/accounts/:account_id/conversations/:id/test_typing_indicators
```

### 3. Test API (MỚI)
```
POST /api/v1/accounts/:account_id/conversations/:id/test_typing_indicators
```

## Cách test typing indicator

### 1. Sử dụng Test API
```bash
curl -X POST "https://app.mooly.vn/api/v1/accounts/220/conversations/4/test_typing_indicators" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

### 2. Sử dụng Bot API
```bash
# Bật typing indicator
curl -X POST "https://app.mooly.vn/api/v1/bot/conversations/4/typing_on" \
  -H "Authorization: Bearer YOUR_BOT_TOKEN"

# Tắt typing indicator  
curl -X POST "https://app.mooly.vn/api/v1/bot/conversations/4/typing_off" \
  -H "Authorization: Bearer YOUR_BOT_TOKEN"
```

### 3. Sử dụng Toggle API (Recommended cho Bot Agents)
```bash
# Với User Token
curl -X POST "https://app.mooly.vn/api/v1/accounts/220/conversations/4/toggle_typing_status" \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"typing_status": "on", "is_private": false}'

# Với Bot Access Token (✅ Mới hỗ trợ)
curl -X POST "https://app.mooly.vn/api/v1/accounts/220/conversations/4/toggle_typing_status" \
  -H "api_access_token: YOUR_BOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"typing_status": "on", "is_private": false}'
```

### 4. Bot Agent Workflow Tối Ưu
```javascript
// Kịch bản: Bot nhận tin nhắn và cần thời gian để "suy nghĩ"
async function handleUserMessage(conversationId, userMessage) {
  try {
    // 1. Bật typing ngay lập tức để user biết bot đang xử lý
    await toggleTyping(conversationId, 'on');

    // 2. Gửi request đến AI service (có thể mất 2-5 giây)
    const aiResponse = await callAIService(userMessage);

    // 3. Tắt typing khi đã có câu trả lời
    await toggleTyping(conversationId, 'off');

    // 4. Gửi tin nhắn cho user
    await sendMessage(conversationId, aiResponse);

  } catch (error) {
    // Luôn tắt typing nếu có lỗi
    await toggleTyping(conversationId, 'off');
  }
}
```

> **Lưu ý**: Bot agents giờ đây có thể sử dụng API `toggle_typing_status` để chủ động kiểm soát typing indicators, tạo trải nghiệm tốt hơn cho người dùng trong quá trình bot xử lý.

## Debugging và Monitoring

### 1. Log Files
Kiểm tra logs để debug:
```bash
# Facebook typing logs
grep "Facebook::TypingIndicatorService" /path/to/logs/production.log

# Instagram typing logs  
grep "Instagram::TypingIndicatorService" /path/to/logs/production.log

# Channel listener logs
grep "Successfully sent.*to.*v22" /path/to/logs/production.log
```

### 2. Common Issues và Solutions

#### Issue: Typing indicator không hiển thị trên mobile
**Solution**: 
- Đảm bảo gửi `mark_seen` trước `typing_on`
- Sử dụng `mark_seen_and_typing` method
- Kiểm tra thời gian chờ giữa các requests

#### Issue: Instagram typing không hoạt động
**Solution**:
- Kiểm tra Instagram channel có access_token hợp lệ
- Verify Instagram API permissions
- Kiểm tra Instagram API version = v22.0

#### Issue: API trả về error
**Solution**:
- Kiểm tra logs để xem error code và message
- Verify Facebook/Instagram app permissions
- Kiểm tra access token còn hạn

### 3. Mobile Testing Checklist
- [ ] Test trên Facebook Messenger mobile app
- [ ] Test trên Instagram mobile app  
- [ ] Test trên desktop browsers
- [ ] Kiểm tra timing giữa mark_seen và typing_on
- [ ] Verify typing indicator tắt sau khi gửi tin nhắn

## Best Practices

1. **Luôn gửi mark_seen trước typing_on** để đảm bảo mobile compatibility
2. **Sử dụng retry logic** để xử lý network issues
3. **Monitor logs** để phát hiện issues sớm
4. **Test trên cả mobile và desktop** 
5. **Tắt typing indicator** sau khi gửi tin nhắn hoặc sau timeout

## Cấu hình Environment Variables

```bash
# Facebook
FACEBOOK_API_VERSION=v22.0
FB_APP_ID=your_app_id
FB_APP_SECRET=your_app_secret

# Instagram  
INSTAGRAM_API_VERSION=v22.0
INSTAGRAM_APP_ID=your_instagram_app_id
INSTAGRAM_APP_SECRET=your_instagram_app_secret
```

## Support

Nếu gặp vấn đề, kiểm tra:
1. Logs trong `/path/to/logs/production.log`
2. Facebook/Instagram app permissions
3. API version configuration
4. Access token validity
