# Facebook Token Refresh System

Hệ thống tự động refresh token Facebook đã được tối ưu hóa để giảm thiểu việc cần reauthorization thủ công và cải thiện trải nghiệm người dùng.

## Tính năng chính

### 1. Tự động Token Refresh
- **Kiểm tra token trước khi gửi tin nhắn**: Mỗi khi gửi tin nhắn, hệ thống sẽ kiểm tra và refresh token nếu cần
- **Refresh định kỳ**: Job chạy mỗi 6 giờ để kiểm tra và refresh token cho tất cả Facebook channels
- **Retry logic thông minh**: Khi gặp lỗi token, hệ thống sẽ tự động thử refresh trước khi đánh dấu cần reauthorization

### 2. UI/UX Cải thiện
- **Banner cảnh báo chi tiết**: Hiển thị thông tin rõ ràng về lỗi token và hướng dẫn khắc phục
- **Auto Refresh Button**: Cho phép user thử refresh token tự động trước khi reauthorization thủ công
- **Trạng thái connection**: Hiển thị trạng thái kết nối trong inbox list với warning icons

### 3. API Endpoints
- `GET /api/v1/accounts/{account_id}/callbacks/facebook_token_status/{inbox_id}`: Kiểm tra trạng thái token
- `POST /api/v1/accounts/{account_id}/callbacks/refresh_facebook_token/{inbox_id}`: Refresh token

## Cách sử dụng

### Cho Admin/Developer

#### 1. Chạy token refresh thủ công
```bash
# Refresh tất cả Facebook tokens
rake facebook:tokens:refresh_all

# Kiểm tra trạng thái token
rake facebook:tokens:check_all

# Refresh token cho channel cụ thể
rake facebook:tokens:refresh_channel[CHANNEL_ID]

# Chạy job refresh
rake facebook:tokens:run_job
```

#### 2. Thiết lập cron job (Production)
```bash
# Thêm vào crontab để chạy mỗi 6 giờ
0 */6 * * * cd /path/to/app && bundle exec rake facebook:tokens:run_job
```

#### 3. Sử dụng với Sidekiq-cron
```ruby
# Trong config/initializers/sidekiq.rb
Sidekiq::Cron::Job.create(
  name: 'Facebook Token Refresh',
  cron: '0 */6 * * *',
  class: 'FacebookTokenRefreshJob'
)
```

### Cho End User

#### 1. Khi gặp lỗi token
1. Vào Settings > Inboxes > [Facebook Inbox]
2. Nếu thấy banner đỏ "Cần kết nối lại":
   - **Bước 1**: Thử click "🔄 Thử refresh tự động" trước
   - **Bước 2**: Nếu không thành công, click "🔗 Kết nối lại thủ công"

#### 2. Lợi ích của Auto Refresh
- ✅ Không mất tin nhắn cũ
- ✅ Không cần đăng nhập Facebook lại
- ✅ Tiết kiệm thời gian
- ✅ Không gián đoạn dịch vụ

## Cơ chế hoạt động

### 1. Token Validation
```ruby
# Kiểm tra token bằng cách gọi Facebook API
api = Koala::Facebook::API.new(page_access_token)
api.get_object(page_id, fields: 'id,name')
```

### 2. Token Refresh Process
1. **Sử dụng User Access Token** để lấy danh sách pages
2. **Tìm page tương ứng** và lấy page access token mới
3. **Cập nhật database** với token mới
4. **Clear reauthorization flag** nếu thành công

### 3. Error Handling
- **Authentication errors**: Tự động trigger refresh
- **Token expiration**: Phát hiện và refresh proactive
- **API rate limits**: Retry với backoff
- **Network errors**: Log và retry

## Monitoring & Logging

### 1. Log Messages
```
# Token validation
Facebook token validation failed for page PAGE_ID: error_message

# Successful refresh
Successfully refreshed Facebook token for page PAGE_ID

# Failed refresh
Failed to refresh Facebook token for page PAGE_ID
```

### 2. Metrics để theo dõi
- Số lượng token refresh thành công/thất bại
- Thời gian response của Facebook API
- Số lượng inbox cần reauthorization
- Tần suất lỗi token

## Troubleshooting

### 1. Token refresh thất bại
**Nguyên nhân thường gặp:**
- User đã thay đổi mật khẩu Facebook
- App permissions bị revoke
- Page bị unpublish hoặc delete
- User không còn admin của page

**Giải pháp:**
1. Kiểm tra page status trên Facebook
2. Verify app permissions
3. Reauthorization thủ công nếu cần

### 2. Job không chạy
**Kiểm tra:**
```bash
# Xem job queue
bundle exec sidekiq

# Test job manually
FacebookTokenRefreshJob.perform_now
```

### 3. API errors
**Common errors:**
- `OAuthException`: Token invalid → Cần reauthorization
- `Rate limit exceeded`: Retry sau
- `Page not found`: Page đã bị xóa

## Best Practices

### 1. Cho Developer
- Luôn handle token errors gracefully
- Implement proper retry logic
- Log chi tiết để debug
- Monitor token health regularly

### 2. Cho User
- Không xóa inbox khi gặp lỗi token
- Thử auto refresh trước khi reauthorization
- Kiểm tra permissions trên Facebook
- Liên hệ support nếu vấn đề kéo dài

## Configuration

### 1. Environment Variables
```bash
FB_APP_ID=your_facebook_app_id
FB_APP_SECRET=your_facebook_app_secret
FB_VERIFY_TOKEN=your_verify_token
```

### 2. Redis Keys
```
# Reauthorization required flag
reauthorization_required:channel_facebook_page:CHANNEL_ID

# Authorization error count
authorization_error_count:channel_facebook_page:CHANNEL_ID
```

## Future Improvements

1. **Proactive token refresh**: Refresh token trước khi hết hạn
2. **Batch processing**: Refresh nhiều tokens cùng lúc
3. **Smart retry**: Adaptive retry intervals
4. **Health dashboard**: UI để monitor token status
5. **Webhook notifications**: Thông báo real-time khi có lỗi token
