# Sử dụng External URL với Instagram trong Chatwoot

Tài liệu này mô tả cách sử dụng external_url để gửi tin nhắn có hình ảnh đến Instagram trong Chatwoot.

## Giới thiệu

Chatwoot hỗ trợ gửi tin nhắn với tệp đính kèm sử dụng external_url cho kênh Instagram. Điều này giúp tối ưu hiệu năng khi gửi tin nhắn có hình ảnh, đặc biệt là khi gửi tin nhắn đến Instagram.

## Lợi ích

- **Hiệu năng tốt hơn**: Không cần tải hình ảnh về Chatwoot trước khi gửi đến Instagram
- **Giảm tải cho máy chủ**: Giảm lưu trữ và xử lý tệp trên máy chủ Chatwoot
- **Tốc độ gửi nhanh hơn**: Gửi tin nhắn nhanh hơn vì không cần tải hình ảnh lên Chatwoot trước

## Cách sử dụng

### Thông qua API

Khi gửi tin nhắn qua API, bạn có thể sử dụng external_url như sau:

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

### Thông qua Bot

Khi sử dụng bot, bạn có thể gửi tin nhắn với external_url như sau:

```javascript
// Ví dụ với JavaScript
await agent.sendMessage({
  content: 'Đây là tin nhắn với hình ảnh từ URL bên ngoài',
  attachments: [
    {
      file_type: 'image',
      external_url: 'https://example.com/image.jpg'
    }
  ]
});
```

## Lưu ý quan trọng

1. **URL phải công khai**: URL phải có thể truy cập công khai từ internet
2. **Định dạng hỗ trợ**: Instagram hỗ trợ các định dạng hình ảnh phổ biến như JPG, PNG, GIF
3. **Kích thước tệp**: Tuân thủ giới hạn kích thước tệp của Instagram (thường là dưới 8MB)
4. **Thời gian tồn tại**: URL nên có thời gian tồn tại đủ dài để Instagram có thể tải hình ảnh

## Xử lý lỗi

Nếu gặp lỗi khi gửi tin nhắn với external_url, hãy kiểm tra:

1. URL có thể truy cập được không
2. Định dạng tệp có được hỗ trợ không
3. Kích thước tệp có vượt quá giới hạn không

## Ví dụ mã nguồn

```ruby
# Ví dụ với Ruby
message = conversation.messages.build(
  account_id: account.id,
  inbox_id: inbox.id,
  message_type: 'outgoing',
  content: 'Đây là tin nhắn với hình ảnh từ URL bên ngoài'
)

message.attachments.build(
  account_id: account.id,
  file_type: :image,
  external_url: 'https://example.com/image.jpg'
)

message.save!
```

## Hỗ trợ

Tính năng này được hỗ trợ cho cả:
- Instagram API trực tiếp (Channel::Instagram)
- Instagram qua Facebook Page (Channel::FacebookPage với instagram_id)
