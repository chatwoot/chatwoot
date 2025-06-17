# Instagram Ads Tracking - Triển khai đầy đủ

## Tổng quan

Tài liệu này mô tả việc triển khai tính năng ads tracking cho Instagram tương tự như Facebook, sử dụng chung infrastructure và UI để quản lý cả hai platform.

## Kiến trúc triển khai

### 1. Shared Infrastructure
- **Database**: Sử dụng chung `FacebookAdsTracking` model (vì Instagram thuộc Meta)
- **UI**: Mở rộng Facebook Dataset UI để hiển thị cả Facebook và Instagram
- **API**: Sử dụng chung Facebook Conversions API cho cả hai platform

### 2. Instagram-specific Components

#### A. Instagram Message Parser
**File**: `lib/integrations/instagram/message_parser.rb`

```ruby
class Integrations::Instagram::MessageParser
  # Tương tự Facebook parser nhưng dành riêng cho Instagram
  # Hỗ trợ referral data từ Instagram ads
end
```

#### B. Instagram Referral Processor
**File**: `app/services/instagram/referral_processor_service.rb`

```ruby
class Instagram::ReferralProcessorService
  # Xử lý referral data từ Instagram ads
  # Tạo conversation và lưu tracking data
end
```

#### C. Instagram Events Job Updates
**File**: `app/jobs/webhooks/instagram_events_job.rb`

- Thêm hỗ trợ `:referral` event
- Xử lý referral events trước khi tạo message thông thường

#### D. Instagram Message Builder Updates
**File**: `app/builders/messages/instagram/base_message_builder.rb`

- Thêm `save_instagram_ads_tracking()` method
- Tự động lưu ads tracking data khi có referral

## Cấu trúc Referral Data

### Instagram Webhook Payload
```json
{
  "sender": {
    "id": "INSTAGRAM_USER_ID"
  },
  "recipient": {
    "id": "INSTAGRAM_BUSINESS_ID"
  },
  "timestamp": 1458692752478,
  "referral": {
    "ref": "REF_DATA_IN_INSTAGRAM_LINK",
    "source": "ADS",
    "type": "OPEN_THREAD",
    "ad_id": "AD_ID",
    "campaign_id": "CAMPAIGN_ID",  // API v22+
    "adset_id": "ADSET_ID",        // API v22+
    "ads_context_data": {
      "ad_title": "AD_TITLE",
      "photo_url": "AD_PHOTO_URL",
      "video_url": "AD_VIDEO_URL",
      "campaign_id": "CAMPAIGN_ID", // Fallback
      "adset_id": "ADSET_ID"        // Fallback
    }
  }
}
```

## UI Enhancements

### 1. Platform Column
- Thêm cột "Platform" trong bảng tracking data
- Badge màu sắc phân biệt:
  - **Facebook**: Blue (#1877f2)
  - **Instagram**: Gradient (Instagram brand colors)

### 2. Platform Detection
```javascript
getPlatformName(tracking) {
  if (tracking.inbox_type === 'Channel::Instagram' || 
      tracking.referral_source === 'INSTAGRAM_ADS') {
    return 'Instagram';
  }
  return 'Facebook';
}
```

### 3. Updated Table Structure
| Date | Contact | **Platform** | Ad ID | Campaign ID | Adset ID | Ref | Event | Status | Actions |

## Database Schema

### Existing FacebookAdsTracking Table
```sql
-- Không cần thay đổi schema, sử dụng chung cho cả Facebook và Instagram
-- Các trường hiện tại đã đủ để lưu trữ Instagram ads data

CREATE TABLE facebook_ads_trackings (
  id bigint PRIMARY KEY,
  conversation_id bigint NOT NULL,
  message_id bigint,
  contact_id bigint NOT NULL,
  inbox_id bigint NOT NULL,
  account_id bigint NOT NULL,
  ref_parameter varchar,
  referral_source varchar,
  referral_type varchar,
  ad_id varchar,
  campaign_id varchar,      -- Hỗ trợ Instagram
  adset_id varchar,         -- Hỗ trợ Instagram
  ad_title varchar,
  ad_photo_url varchar,
  ad_video_url varchar,
  raw_referral_data json,
  conversion_sent boolean DEFAULT false,
  conversion_sent_at timestamp,
  conversion_response json,
  event_name varchar,
  event_value decimal(10,2),
  currency varchar DEFAULT 'USD',
  additional_attributes json,
  created_at timestamp,
  updated_at timestamp
);
```

## Model Updates

### FacebookAdsTracking Model
```ruby
class FacebookAdsTracking < ApplicationRecord
  # Thêm methods để phân biệt platform
  def instagram_tracking?
    inbox.instagram?
  end

  def facebook_tracking?
    inbox.facebook?
  end

  # Cập nhật conversion event data cho cả hai platform
  def build_event_source_url
    if inbox.instagram?
      "https://www.instagram.com/direct/t/#{contact.get_source_id(inbox.id)}?ref=#{ref_parameter}"
    else
      "https://m.me/#{inbox.channel.page_id}?ref=#{ref_parameter}"
    end
  end

  # Summary data bao gồm platform info
  def summary_data
    {
      # ... existing fields ...
      inbox_type: inbox.channel_type,
      platform: instagram_tracking? ? 'Instagram' : 'Facebook'
    }
  end
end
```

## Workflow

### 1. Instagram Ads → Message Flow
```
Instagram Ad Click
    ↓
Instagram Webhook (with referral data)
    ↓
InstagramEventsJob.process_referral_event()
    ↓
Instagram::ReferralProcessorService.perform()
    ↓
FacebookAdsTracking.create() (shared model)
    ↓
Facebook::SendConversionEventJob (shared job)
```

### 2. Regular Instagram Message Flow
```
Instagram Message
    ↓
InstagramEventsJob.message()
    ↓
Instagram::MessageBuilder.build_message()
    ↓
save_instagram_ads_tracking() (if referral data exists)
```

## Configuration

### 1. Shared Dataset Configuration
- Instagram sử dụng chung Facebook Dataset configuration
- Cùng Pixel ID và Access Token
- Cùng conversion events settings

### 2. Webhook Configuration
- Instagram webhook đã hỗ trợ referral events
- Không cần thay đổi webhook setup

## Testing

### 1. Instagram Referral Event Test
```json
{
  "object": "instagram",
  "entry": [{
    "id": "INSTAGRAM_BUSINESS_ID",
    "time": 1234567890,
    "messaging": [{
      "sender": {"id": "INSTAGRAM_USER_ID"},
      "recipient": {"id": "INSTAGRAM_BUSINESS_ID"},
      "timestamp": 1234567890,
      "referral": {
        "ref": "test_instagram_ref",
        "source": "ADS",
        "type": "OPEN_THREAD",
        "ad_id": "123456789",
        "campaign_id": "987654321",
        "adset_id": "456789123"
      }
    }]
  }]
}
```

### 2. UI Testing
- Kiểm tra platform badge hiển thị đúng
- Verify Instagram tracking data xuất hiện trong bảng
- Test conversion event sending cho Instagram

## Benefits

### 1. Unified Management
- Quản lý ads tracking cho cả Facebook và Instagram trong một UI
- Shared configuration và settings
- Consistent reporting và analytics

### 2. Complete Meta Ecosystem
- Hỗ trợ đầy đủ Meta advertising platforms
- Unified conversion tracking
- Better ROI measurement across platforms

### 3. Scalability
- Dễ dàng mở rộng cho các Meta products khác
- Shared infrastructure giảm maintenance overhead
- Consistent user experience

## Migration

### Existing Data
- Không cần migration vì sử dụng chung database schema
- Instagram tracking data sẽ tự động được phân biệt qua inbox_type

### New Installations
- Instagram ads tracking hoạt động ngay lập tức
- Sử dụng chung Facebook Dataset configuration

## Monitoring

### Logs to Monitor
- `Instagram Events Job Messaging: ...`
- `Processed Instagram referral event for sender ...`
- `Saved Instagram ads tracking data: ... for conversation ...`

### Metrics
- Instagram vs Facebook tracking volume
- Conversion rates by platform
- Performance comparison between platforms

## Conclusion

Việc triển khai Instagram ads tracking đã được hoàn thành với:
1. **Full feature parity** với Facebook ads tracking
2. **Shared infrastructure** để giảm complexity
3. **Enhanced UI** để quản lý cả hai platforms
4. **Backward compatibility** với existing Facebook setup
5. **Future-ready architecture** cho Meta ecosystem expansion

Instagram ads tracking bây giờ hoạt động seamlessly cùng với Facebook, cung cấp unified view cho toàn bộ Meta advertising ecosystem! 🚀
