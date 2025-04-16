# Gửi tin nhắn với tệp đính kèm sử dụng external_url

Tài liệu này mô tả cách gửi tin nhắn với tệp đính kèm sử dụng external_url trong Chatwoot.

## Giới thiệu

Chatwoot hỗ trợ gửi tin nhắn với tệp đính kèm sử dụng external_url. Điều này giúp tối ưu hiệu năng khi gửi tin nhắn có hình ảnh, đặc biệt là khi gửi tin nhắn đến Facebook.

## API Endpoint

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
```

## Tham số

| Tham số | Kiểu | Mô tả |
|---------|------|-------|
| content | string | Nội dung của tin nhắn |
| attachments | array | Mảng các tệp đính kèm |
| attachments[].file_type | string | Loại tệp đính kèm (image, audio, video, file) |
| attachments[].external_url | string | URL bên ngoài của tệp đính kèm |
| private | boolean | Cờ để xác định xem tin nhắn có phải là ghi chú riêng tư không |

## Ví dụ

### Gửi tin nhắn với tệp đính kèm sử dụng external_url

```json
{
  "content": "Đây là tin nhắn với hình ảnh từ URL bên ngoài",
  "attachments": [
    {
      "file_type": "image",
      "external_url": "https://example.com/image.jpg"
    }
  ],
  "private": false
}
```

### Phản hồi

```json
{
  "id": 123,
  "content": "Đây là tin nhắn với hình ảnh từ URL bên ngoài",
  "inbox_id": 1,
  "conversation_id": 1,
  "message_type": 1,
  "created_at": 1619086034,
  "private": false,
  "attachments": [
    {
      "id": 1,
      "message_id": 123,
      "file_type": "image",
      "account_id": 1,
      "extension": "jpg",
      "data_url": "https://example.com/image.jpg",
      "thumb_url": "https://example.com/image.jpg",
      "file_size": null,
      "width": null,
      "height": null
    }
  ],
  "sender": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "avatar": "https://example.com/avatar.jpg",
    "type": "user"
  }
}
```

## Lưu ý

- Khi sử dụng external_url, Chatwoot sẽ không tải tệp đính kèm về máy chủ, mà sẽ sử dụng URL bên ngoài trực tiếp.
- Điều này giúp tối ưu hiệu năng khi gửi tin nhắn có hình ảnh, đặc biệt là khi gửi tin nhắn đến Facebook.
- Đảm bảo rằng URL bên ngoài có thể truy cập được từ máy chủ Chatwoot và từ người nhận tin nhắn.
- Đối với Facebook, URL bên ngoài phải có thể truy cập được từ Facebook.

## Ưu điểm

- Giảm thời gian gửi tin nhắn có hình ảnh vì không cần tải hình ảnh về Chatwoot trước
- Giảm tải cho máy chủ Chatwoot vì không cần lưu trữ hình ảnh tạm thời
- Đơn giản hóa quy trình gửi hình ảnh, giảm độ phức tạp của code
- Tối ưu hóa hiệu năng mạng vì hình ảnh chỉ cần được tải một lần (từ URL gốc đến Facebook)

## Nhược điểm

- Phụ thuộc vào tính khả dụng của URL hình ảnh gốc (nếu URL gốc không khả dụng, Facebook sẽ không thể tải hình ảnh)
- Có thể gặp vấn đề với các URL có thời gian sống ngắn (nếu URL hết hạn trước khi Facebook tải hình ảnh)
