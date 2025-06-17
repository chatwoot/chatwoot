# API Chatbot cho Chatwoot

Tài liệu này mô tả các API tối ưu hóa cho chatbot trong Chatwoot.

## Giới thiệu

API Chatbot được thiết kế để tối ưu hóa hiệu suất gửi và nhận tin nhắn cho chatbot AI. Các API này cung cấp các endpoint đơn giản và hiệu quả để:

1. Gửi tin nhắn với hiệu suất cao
2. Gửi nhiều tin nhắn cùng lúc
3. Điều khiển typing indicator
4. Sử dụng external URL cho tệp đính kèm

## Xác thực

Tất cả các API đều yêu cầu xác thực bằng API key. Thêm header sau vào tất cả các request:

```
api_access_token: YOUR_API_KEY
```

## API Endpoints

### 1. Gửi tin nhắn

```
POST /api/v1/accounts/:account_id/bot/messages
```

#### Tham số

| Tham số | Kiểu | Mô tả |
|---------|------|-------|
| conversation_id | string | ID của cuộc hội thoại |
| content | string | Nội dung tin nhắn |
| message_type | string | Loại tin nhắn (mặc định: outgoing) |
| private | boolean | Tin nhắn riêng tư hay không (mặc định: false) |
| attachments | array | Mảng các tệp đính kèm |

#### Ví dụ

```json
{
  "conversation_id": "12345",
  "content": "Xin chào! Tôi có thể giúp gì cho bạn?",
  "attachments": [
    {
      "external_url": "https://example.com/image.jpg",
      "file_type": "image"
    }
  ]
}
```

### 2. Gửi nhiều tin nhắn cùng lúc

```
POST /api/v1/accounts/:account_id/bot/messages/batch_create
```

#### Tham số

| Tham số | Kiểu | Mô tả |
|---------|------|-------|
| messages | array | Mảng các tin nhắn cần gửi |

#### Ví dụ

```json
{
  "messages": [
    {
      "conversation_id": "12345",
      "content": "Tin nhắn 1",
      "attachments": [
        {
          "external_url": "https://example.com/image1.jpg",
          "file_type": "image"
        }
      ]
    },
    {
      "conversation_id": "12345",
      "content": "Tin nhắn 2"
    }
  ]
}
```

### 3. Điều khiển typing indicator

#### Bật typing indicator

```
POST /api/v1/accounts/:account_id/bot/conversations/:id/typing_on
```

#### Tắt typing indicator

```
POST /api/v1/accounts/:account_id/bot/conversations/:id/typing_off
```

#### Đánh dấu tin nhắn đã xem

```
POST /api/v1/accounts/:account_id/bot/conversations/:id/mark_seen
```

### 4. Tạo attachment với external URL

```
POST /api/v1/accounts/:account_id/bot/attachments/external
```

#### Tham số

| Tham số | Kiểu | Mô tả |
|---------|------|-------|
| external_url | string | URL của tệp đính kèm |
| file_type | string | Loại tệp (image, audio, video, file) |

#### Ví dụ

```json
{
  "external_url": "https://example.com/image.jpg",
  "file_type": "image"
}
```

## Các bước tối ưu để gửi tin nhắn

Để đạt hiệu suất tối ưu khi gửi tin nhắn với chatbot, hãy làm theo các bước sau:

1. **Đánh dấu tin nhắn đã xem**: Gọi API `mark_seen` để đánh dấu tin nhắn đã xem
2. **Bật typing indicator**: Gọi API `typing_on` để hiển thị typing indicator
3. **Đợi một khoảng thời gian ngắn**: Đợi khoảng 1-2 giây để người dùng thấy typing indicator
4. **Gửi tin nhắn**: Gọi API `messages` để gửi tin nhắn
5. **Tắt typing indicator**: Gọi API `typing_off` để tắt typing indicator

## Lưu ý quan trọng

1. **Typing Indicator**: Hệ thống KHÔNG tự động gửi typing indicator khi gửi tin nhắn. Bạn cần chủ động gọi API typing khi cần thiết
2. **External URL**: Ưu tiên sử dụng external URL cho tệp đính kèm để tối ưu hiệu suất và tránh duplicate storage
3. **Batch Messages**: Đối với tin nhắn có nhiều tệp đính kèm, sử dụng API `batch_create` để gửi tất cả cùng lúc
4. **URL Accessibility**: Đảm bảo URL của tệp đính kèm có thể truy cập công khai từ Facebook/Instagram
5. **Performance**: Khi sử dụng external_url, hình ảnh sẽ được gửi trực tiếp đến Facebook mà không cần tải về server Chatwoot

## Ví dụ mã nguồn

### Gửi tin nhắn đơn giản (Node.js)

```javascript
const axios = require('axios');

async function sendMessage(conversationId, content, attachments = []) {
  const baseUrl = 'https://your-chatwoot-instance.com/api/v1/accounts/1/bot';
  const headers = {
    'api_access_token': 'YOUR_API_KEY',
    'Content-Type': 'application/json'
  };

  try {
    // Gửi tin nhắn trực tiếp - không có typing tự động
    const response = await axios.post(`${baseUrl}/messages`, {
      conversation_id: conversationId,
      content,
      attachments
    }, { headers });

    return response.data;
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
}

// Nếu cần typing indicator, gọi riêng biệt
async function sendMessageWithTyping(conversationId, content, attachments = []) {
  const baseUrl = 'https://your-chatwoot-instance.com/api/v1/accounts/1/bot';
  const headers = {
    'api_access_token': 'YOUR_API_KEY',
    'Content-Type': 'application/json'
  };

  try {
    // Bật typing indicator (tùy chọn)
    await axios.post(`${baseUrl}/conversations/${conversationId}/typing_on`, {}, { headers });

    // Đợi 1.5 giây để hiển thị typing indicator
    await new Promise(resolve => setTimeout(resolve, 1500));

    // Gửi tin nhắn
    const response = await axios.post(`${baseUrl}/messages`, {
      conversation_id: conversationId,
      content,
      attachments
    }, { headers });

    // Tắt typing indicator
    await axios.post(`${baseUrl}/conversations/${conversationId}/typing_off`, {}, { headers });

    return response.data;
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
}
```

## Hiệu suất

Các API này được tối ưu hóa để đạt hiệu suất cao:

1. Sử dụng eager loading để giảm số lượng truy vấn database
2. Tối ưu hóa việc gửi tệp đính kèm bằng cách sử dụng external URL
3. Xử lý bất đồng bộ các tác vụ không cần phản hồi ngay lập tức
4. Sử dụng batch processing để gửi nhiều tin nhắn cùng lúc
