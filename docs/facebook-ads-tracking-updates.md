# Facebook Ads Tracking - Cập nhật API v22+ và UI

## Tổng quan

Tài liệu này mô tả các cập nhật được thực hiện để đảm bảo Facebook ads tracking tương thích với Facebook Graph API v22+ mới nhất và cải thiện UI hiển thị.

## Các cập nhật chính

### 1. Cập nhật Facebook Message Parser

#### File: `lib/integrations/facebook/message_parser.rb`

**Thêm mới:**
- `referral_campaign_id()` - Lấy campaign_id từ referral data
- `referral_adset_id()` - Lấy adset_id từ referral data

**Cải thiện:**
- Hỗ trợ cấu trúc mới của Facebook API v22+ với campaign_id và adset_id ở root level
- Fallback logic để lấy từ ads_context_data nếu không có ở root level

#### Cấu trúc referral data mới:
```json
{
  "referral": {
    "ref": "REF_DATA_IN_M_DOT_ME_PARAM",
    "source": "SHORTLINK",
    "type": "OPEN_THREAD",
    "ad_id": "AD_ID",
    "campaign_id": "CAMPAIGN_ID",  // Mới trong API v22+
    "adset_id": "ADSET_ID",        // Mới trong API v22+
    "ads_context_data": {
      "ad_title": "AD_TITLE",
      "photo_url": "AD_PHOTO_URL",
      "video_url": "AD_VIDEO_URL",
      "campaign_id": "CAMPAIGN_ID", // Fallback location
      "adset_id": "ADSET_ID"        // Fallback location
    }
  }
}
```

### 2. Cập nhật Logic Lưu trữ

#### Files:
- `app/builders/messages/facebook/message_builder.rb`
- `app/services/facebook/referral_processor_service.rb`

**Thay đổi:**
- Thêm `campaign_id` và `adset_id` vào tracking_data khi lưu
- Sử dụng các phương thức mới từ message parser

### 3. Cải thiện Model FacebookAdsTracking

#### File: `app/models/facebook_ads_tracking.rb`

**Cập nhật `extract_campaign_and_adset_ids()`:**
1. **Ưu tiên cao nhất**: Lấy từ root level của referral data (API v22+)
2. **Ưu tiên trung bình**: Lấy từ ads_context_data (API cũ)
3. **Fallback**: Extract từ ad_title hoặc các trường text khác

**Logic mới:**
```ruby
# Ưu tiên từ root level (API v22+)
self.campaign_id ||= raw_referral_data['campaign_id']
self.adset_id ||= raw_referral_data['adset_id']

# Fallback từ ads_context_data
ads_context = raw_referral_data['ads_context_data'] || {}
self.campaign_id ||= ads_context['campaign_id']
self.adset_id ||= ads_context['adset_id']

# Fallback cuối từ text parsing
self.campaign_id ||= extract_id_from_url(ads_context['ad_title'], 'campaign')
self.adset_id ||= extract_id_from_url(ads_context['ad_title'], 'adset')
```

### 4. Cập nhật Vue UI

#### File: `app/javascript/dashboard/routes/dashboard/settings/inbox/facebook/FacebookDataset.vue`

**Thêm cột mới:**
- Campaign ID
- Adset ID

**Cấu trúc table mới:**
| Date | Contact | Ad ID | Campaign ID | Adset ID | Ref Parameter | Event Name | Status | Actions |

### 5. Cập nhật Translations

#### Files:
- `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- `app/javascript/dashboard/i18n/locale/vi/inboxMgmt.json`

**Thêm keys mới:**
- `CAMPAIGN_ID`: "Campaign ID" / "ID Chiến dịch"
- `ADSET_ID`: "Adset ID" / "ID Nhóm quảng cáo"

## Lợi ích của việc cập nhật

### 1. Tương thích API mới nhất
- Hỗ trợ Facebook Graph API v22+ với cấu trúc referral data mới
- Backward compatible với API cũ
- Tự động fallback khi không có data mới

### 2. Thông tin ads chi tiết hơn
- Hiển thị đầy đủ Campaign ID và Adset ID
- Dễ dàng tracking và phân tích hiệu quả quảng cáo
- Liên kết trực tiếp với Facebook Ads Manager

### 3. UI/UX cải thiện
- Bảng hiển thị đầy đủ thông tin ads
- Dễ dàng identify nguồn traffic từ ads
- Hỗ trợ tốt hơn cho việc phân tích ROI

## Testing

### 1. Test với referral data mới (API v22+)
```json
{
  "referral": {
    "ref": "test_ref_123",
    "source": "ADS",
    "type": "OPEN_THREAD",
    "ad_id": "123456789",
    "campaign_id": "987654321",
    "adset_id": "456789123",
    "ads_context_data": {
      "ad_title": "Test Ad Title",
      "photo_url": "https://example.com/photo.jpg"
    }
  }
}
```

### 2. Test với referral data cũ (fallback)
```json
{
  "referral": {
    "ref": "test_ref_123",
    "source": "ADS", 
    "type": "OPEN_THREAD",
    "ad_id": "123456789",
    "ads_context_data": {
      "ad_title": "Test Ad Title",
      "photo_url": "https://example.com/photo.jpg",
      "campaign_id": "987654321",
      "adset_id": "456789123"
    }
  }
}
```

### 3. Kiểm tra UI
- Truy cập Facebook Dataset settings
- Kiểm tra bảng tracking data hiển thị đầy đủ cột
- Verify campaign_id và adset_id hiển thị chính xác

## Migration

Không cần migration database vì:
- Các cột `campaign_id` và `adset_id` đã tồn tại
- Logic mới sẽ tự động extract data cho records mới
- Records cũ vẫn hoạt động bình thường

## Monitoring

### Logs để theo dõi:
- `Facebook::SendOnFacebookService: Sending attachment with URL: ... (external: true/false)`
- `Saved Facebook ads tracking data: ... for conversation ...`
- Kiểm tra `raw_referral_data` trong database để verify cấu trúc mới

### Metrics quan trọng:
- Tỷ lệ records có campaign_id và adset_id
- Accuracy của data extraction
- Performance của UI với cột mới

## Kết luận

Các cập nhật này đảm bảo:
1. **Tương thích** với Facebook API v22+ mới nhất
2. **Backward compatibility** với API cũ
3. **UI cải thiện** với thông tin ads đầy đủ hơn
4. **Robust fallback logic** cho data extraction

Hệ thống bây giờ có thể tracking ads data chính xác hơn và cung cấp insights tốt hơn cho việc tối ưu quảng cáo Facebook.
