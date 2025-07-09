# Facebook/Instagram Ads Tracking Guide

## Tổng quan

Hệ thống ads tracking của Chatwoot/Mooly cho phép theo dõi và phân tích hiệu quả quảng cáo Facebook và Instagram khi khách hàng nhắn tin từ ads.

## Tính năng chính

### 1. Tự động thu thập thông tin ads
- **Ad ID**: ID của quảng cáo
- **Campaign ID**: ID của chiến dịch quảng cáo
- **Adset ID**: ID của nhóm quảng cáo
- **Referral data**: Thông tin nguồn truy cập
- **UTM parameters**: Các tham số tracking tùy chỉnh

### 2. Tích hợp Facebook Graph API v22
- Tự động lấy thông tin chi tiết từ Facebook API
- Cập nhật thông tin performance metrics
- Hỗ trợ cả Facebook và Instagram ads

### 3. Conversion tracking
- Gửi conversion events về Facebook
- Tối ưu hóa quảng cáo dựa trên dữ liệu thực tế
- Hỗ trợ Facebook Conversions API

## Cách hoạt động

### 1. Khi khách hàng nhắn tin từ ads

```
Facebook/Instagram Ad Click
    ↓
Webhook với referral data
    ↓
Tự động lưu ads tracking data
    ↓
Schedule job cập nhật thông tin từ API
    ↓
Gửi conversion event (nếu được cấu hình)
```

### 2. Cấu trúc dữ liệu tracking

```ruby
FacebookAdsTracking {
  conversation_id: "ID cuộc trò chuyện",
  ad_id: "ID quảng cáo",
  campaign_id: "ID chiến dịch", 
  adset_id: "ID nhóm quảng cáo",
  ref_parameter: "Tham số ref từ link",
  referral_source: "ADS/SHORTLINK",
  referral_type: "OPEN_THREAD",
  ad_title: "Tiêu đề quảng cáo",
  raw_referral_data: "Dữ liệu webhook gốc",
  additional_attributes: {
    ads_api_info: "Thông tin từ Facebook API"
  }
}
```

## Cấu hình

### 1. Facebook/Instagram Channel
- Đảm bảo có access token hợp lệ
- Cấp quyền ads_read cho app
- Kích hoạt webhook cho messaging_referrals

### 2. Dataset Configuration (tùy chọn)
- Cấu hình Facebook Pixel ID
- Thiết lập Conversions API token
- Bật auto conversion tracking

### 3. URL Parameters
Để tracking chính xác, thêm parameters vào ads URL:

```
https://m.me/your-page?ref=campaign_123_adset_456
```

Hoặc sử dụng UTM parameters:
```
https://m.me/your-page?utm_campaign=123&utm_adset=456
```

## API Endpoints

### 1. Lấy ads tracking data cho conversation
```
GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/ads_tracking
```

### 2. Lấy tổng hợp ads tracking data
```
GET /api/v1/accounts/{account_id}/facebook_dataset
```

### 3. Xuất dữ liệu CSV
```
GET /api/v1/accounts/{account_id}/facebook_dataset/export?format=csv
```

## Troubleshooting

### 1. Lỗi routing "No route matches [GET] /api/v1/accounts/{id}/{id}/ads_tracking"
- Đảm bảo gọi đúng URL với conversation_id
- Kiểm tra conversationId được truyền đúng trong component

### 2. Không thu thập được campaign_id/adset_id
- Kiểm tra Facebook API version (khuyến nghị v22.0+)
- Đảm bảo ads có cấu hình referral parameters
- Xem log để kiểm tra raw_referral_data

### 3. Conversion events không được gửi
- Kiểm tra cấu hình Facebook Dataset
- Đảm bảo có access token và pixel ID hợp lệ
- Xem Sidekiq queue cho job failures

## Best Practices

### 1. URL Design
- Sử dụng ref parameters có ý nghĩa: `ref=campaign_{campaign_id}_adset_{adset_id}`
- Thêm UTM parameters để tracking chi tiết hơn
- Tránh sử dụng ký tự đặc biệt trong ref

### 2. Performance
- Ads info update job chạy với delay 30s để đảm bảo Facebook API có dữ liệu
- Sử dụng low_priority queue cho update jobs
- Cache thông tin ads để tránh gọi API quá nhiều

### 3. Monitoring
- Theo dõi log để phát hiện lỗi sớm
- Kiểm tra conversion rate trong Facebook Ads Manager
- Sử dụng test events để verify setup

## Tích hợp với CRM

Dữ liệu ads tracking có thể được xuất và tích hợp với các hệ thống CRM:

```ruby
# Lấy dữ liệu tracking
trackings = FacebookAdsTracking.includes(:conversation, :contact)
                               .where(created_at: 1.week.ago..Time.current)

# Xuất sang CRM format
trackings.map(&:summary_data)
```

## Báo cáo và Analytics

### 1. Top performing ads
```ruby
FacebookAdsTracking.group(:ad_id, :ad_title)
                   .count
                   .sort_by { |_, count| -count }
```

### 2. Conversion rate by campaign
```ruby
FacebookAdsTracking.group(:campaign_id)
                   .group(:conversion_sent)
                   .count
```

### 3. Revenue attribution
```ruby
FacebookAdsTracking.joins(:conversation)
                   .where(conversations: { status: 'resolved' })
                   .sum(:event_value)
```
