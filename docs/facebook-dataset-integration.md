# Facebook Dataset & Conversions API Integration

Tính năng Facebook Dataset cho phép theo dõi nguồn tin nhắn từ quảng cáo Facebook và gửi sự kiện chuyển đổi về Facebook để tối ưu hóa quảng cáo.

## Tính năng chính

### 1. Theo dõi nguồn tin nhắn từ quảng cáo
- Tự động nhận diện tin nhắn đến từ Facebook ads thông qua `messaging_referrals` webhook
- Lưu trữ thông tin chi tiết: Ad ID, Campaign ID, Ref parameter, Ad title
- Theo dõi conversion events và gửi về Facebook Conversions API

### 2. Facebook Conversions API Integration
- Gửi server-side events về Facebook để tracking chính xác
- Hỗ trợ test events với test event code
- Retry logic và error handling
- Bulk resend conversion events

### 3. Analytics & Reporting
- Dashboard phân tích hiệu suất quảng cáo
- Thống kê conversion rates theo nguồn
- Top performing ads
- Export dữ liệu CSV
- Real-time tracking data

## Cấu hình

### 1. Facebook App Setup
1. Tạo Facebook App tại https://developers.facebook.com/
2. Thêm Messenger Platform product
3. Cấu hình webhook subscription để nhận `messaging_referrals` events
4. Tạo Facebook Pixel và lấy Pixel ID
5. Tạo Conversions API Access Token

### 2. Chatwoot Configuration
1. Vào Settings > Inboxes > [Facebook Inbox] > Facebook Dataset
2. Bật "Enable Facebook Dataset Tracking"
3. Nhập thông tin:
   - **Facebook Pixel ID**: ID của Facebook Pixel
   - **Conversions API Access Token**: Token để gửi server-side events
   - **Test Event Code** (optional): Để test events trước khi go live
   - **Default Event Name**: Tên event mặc định (Lead, Contact, etc.)
   - **Default Event Value**: Giá trị event mặc định
   - **Default Currency**: Tiền tệ mặc định

### 3. Facebook Ads Setup
Để tracking hoạt động, cần cấu hình ads với ref parameter:

```
https://m.me/YOUR_PAGE_ID?ref=YOUR_TRACKING_PARAMETER
```

Ví dụ:
```
https://m.me/123456789?ref=campaign_summer_2024_ad_001
```

## Cách hoạt động

### 1. Message Flow
```
Facebook Ad Click → Messenger → Chatwoot Webhook →
Referral Processing → Save Tracking Data → Send Conversion Event
```

### 2. Webhook Events
Chatwoot nhận và xử lý các webhook events:
- `messaging_referrals`: Khi user click từ ads
- `messages`: Tin nhắn thường
- `postbacks`: Button clicks

### 3. Conversion Events
Tự động gửi conversion events về Facebook với thông tin:
```json
{
  "event_name": "Lead",
  "event_time": 1640995200,
  "action_source": "chat",
  "user_data": {
    "external_id": "contact_123",
    "fb_login_id": "facebook_user_id"
  },
  "custom_data": {
    "content_name": "Ad Title",
    "content_category": "messaging",
    "value": 0,
    "currency": "USD",
    "content_ids": ["ad_id"]
  }
}
```

## 🎯 Events Tự Động & Tối Ưu Hóa Ads

### 1. Events Được Gửi Tự Động

#### Lead Event (Mặc định)
Khi khách hàng nhắn tin từ Facebook ads, hệ thống tự động gửi:
- **Event Name**: `Lead` (có thể thay đổi trong settings)
- **Trigger**: Ngay khi có tin nhắn đầu tiên từ ads
- **Frequency**: 1 lần duy nhất cho mỗi conversation
- **Timing**: Real-time (gửi ngay lập tức)

#### Điều kiện gửi Event:
- ✅ Tin nhắn có `messaging_referrals` data
- ✅ Facebook Dataset được bật cho inbox
- ✅ Có Pixel ID và Access Token hợp lệ
- ✅ Chưa gửi conversion cho conversation này

### 2. Cấu hình Events cho Tối Ưu Ads

#### A. Lead Generation Campaigns
```json
{
  "default_event_name": "Lead",
  "default_event_value": 25,
  "default_currency": "USD"
}
```
**Khi nào sử dụng**: Campaigns thu thập thông tin khách hàng tiềm năng
**Facebook sẽ tối ưu**: Cost per Lead, tìm người có khả năng để lại thông tin

#### B. E-commerce/Sales Campaigns
```json
{
  "default_event_name": "InitiateCheckout",
  "default_event_value": 100,
  "default_currency": "USD"
}
```
**Khi nào sử dụng**: Campaigns bán sản phẩm/dịch vụ
**Facebook sẽ tối ưu**: Tìm người có khả năng mua hàng cao

#### C. High-Value Services
```json
{
  "default_event_name": "Contact",
  "default_event_value": 200,
  "default_currency": "USD"
}
```
**Khi nào sử dụng**: Dịch vụ tư vấn, bảo hiểm, bất động sản
**Facebook sẽ tối ưu**: Tìm khách hàng có giá trị cao

#### D. App/Service Registration
```json
{
  "default_event_name": "CompleteRegistration",
  "default_event_value": 50,
  "default_currency": "USD"
}
```
**Khi nào sử dụng**: Đăng ký app, dịch vụ, membership
**Facebook sẽ tối ưu**: Tìm người có khả năng đăng ký cao

### 3. Chiến lược Event Values

#### Cách tính Event Value chính xác:
1. **Customer Lifetime Value (CLV)**: Giá trị trung bình khách hàng mang lại
2. **Average Order Value (AOV)**: Giá trị đơn hàng trung bình
3. **Conversion Rate**: Tỷ lệ từ lead thành khách hàng
4. **Profit Margin**: Lợi nhuận từ mỗi conversion

#### Ví dụ tính toán:
```
CLV = $500 (giá trị khách hàng trung bình)
Lead to Customer Rate = 20%
Event Value = $500 × 20% = $100
```

### 4. Ref Parameter Strategy

#### Naming Convention khuyến nghị:
```
campaign_{campaign_type}_value_{event_value}_target_{audience}

Ví dụ:
- campaign_leadgen_value_25_target_young
- campaign_sales_value_100_target_premium
- campaign_service_value_200_target_business
```

#### URL Examples:
```
https://m.me/YOUR_PAGE_ID?ref=campaign_leadgen_value_25_target_young
https://m.me/YOUR_PAGE_ID?ref=campaign_sales_value_100_target_premium
https://m.me/YOUR_PAGE_ID?ref=campaign_service_value_200_target_business
```

## 🔧 API Reference cho Developers

### 1. Inbox Facebook Dataset Configuration

#### Lấy cấu hình hiện tại
```http
GET /api/v1/accounts/{account_id}/inboxes/{inbox_id}/facebook_dataset
Authorization: Bearer {api_token}
```

**Response:**
```json
{
  "enabled": true,
  "config": {
    "pixel_id": "123456789",
    "access_token": "***",
    "test_event_code": "TEST123",
    "default_event_name": "Lead",
    "default_event_value": 25,
    "default_currency": "USD",
    "auto_send_conversions": true
  },
  "tracking_stats": {
    "total_trackings": 150,
    "conversions_sent": 145,
    "pending_conversions": 5,
    "unique_ads": 12,
    "unique_campaigns": 3
  }
}
```

#### Cập nhật cấu hình
```http
PUT /api/v1/accounts/{account_id}/inboxes/{inbox_id}/facebook_dataset
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "facebook_dataset": {
    "enabled": true,
    "pixel_id": "123456789",
    "access_token": "your_conversions_api_token",
    "test_event_code": "TEST123",
    "default_event_name": "Lead",
    "default_event_value": 25,
    "default_currency": "USD",
    "auto_send_conversions": true
  }
}
```

#### Test kết nối Facebook
```http
POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/facebook_dataset/test_connection
Authorization: Bearer {api_token}
```

**Response thành công:**
```json
{
  "success": true,
  "message": "Facebook Dataset connection successful",
  "details": {
    "events_received": 1,
    "fbtrace_id": "ABC123..."
  }
}
```

#### Lấy tracking data của inbox
```http
GET /api/v1/accounts/{account_id}/inboxes/{inbox_id}/facebook_dataset/tracking_data?page=1&per_page=20
Authorization: Bearer {api_token}
```

**Response:**
```json
{
  "data": [
    {
      "id": 123,
      "ref_parameter": "campaign_leadgen_value_25",
      "referral_source": "ADS",
      "ad_id": "23847656340570",
      "campaign_id": "23847656340569",
      "event_name": "Lead",
      "event_value": 25,
      "conversion_sent": true,
      "conversion_sent_at": "2024-01-15T10:30:00Z",
      "contact_name": "John Doe",
      "contact_email": "john@example.com",
      "created_at": "2024-01-15T10:25:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

#### Gửi lại conversion event
```http
POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/facebook_dataset/resend_conversion/{tracking_id}
Authorization: Bearer {api_token}
```

### 2. Account-level Analytics APIs

#### Lấy tất cả tracking data
```http
GET /api/v1/accounts/{account_id}/facebook_dataset?start_date=2024-01-01&end_date=2024-01-31&inbox_id=123&conversion_status=sent
Authorization: Bearer {api_token}
```

**Query Parameters:**
- `start_date`: YYYY-MM-DD format
- `end_date`: YYYY-MM-DD format
- `inbox_id`: Filter theo inbox cụ thể
- `conversion_status`: `sent`, `pending`, hoặc bỏ trống
- `referral_source`: `ADS`, `SHORTLINK`, etc.
- `ad_id`: Filter theo Ad ID cụ thể
- `campaign_id`: Filter theo Campaign ID
- `page`: Số trang (default: 1)
- `per_page`: Số records per page (max: 100)

#### Lấy thống kê tổng quan
```http
GET /api/v1/accounts/{account_id}/facebook_dataset/stats?start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer {api_token}
```

**Response:**
```json
{
  "total_trackings": 500,
  "conversions_sent": 485,
  "pending_conversions": 15,
  "unique_ads": 25,
  "unique_campaigns": 8,
  "unique_contacts": 450,
  "total_event_value": 12500,
  "by_source": {
    "ADS": 450,
    "SHORTLINK": 50
  },
  "by_event": {
    "Lead": 400,
    "Contact": 100
  },
  "daily_stats": [
    {
      "date": "2024-01-01",
      "total": 15,
      "conversions_sent": 14,
      "unique_contacts": 12
    }
  ],
  "top_ads": [
    {
      "ad_id": "23847656340570",
      "ad_title": "Special Offer - 50% Off",
      "campaign_id": "23847656340569",
      "total_trackings": 45,
      "conversions_sent": 43,
      "total_value": 1125,
      "conversion_rate": 95.56
    }
  ],
  "conversion_rates": [
    {
      "source": "ADS",
      "total_trackings": 450,
      "conversions_sent": 435,
      "conversion_rate": 96.67
    }
  ]
}
```

#### Export dữ liệu CSV
```http
GET /api/v1/accounts/{account_id}/facebook_dataset/export?format=csv&start_date=2024-01-01&end_date=2024-01-31
Authorization: Bearer {api_token}
```

#### Bulk resend conversions
```http
POST /api/v1/accounts/{account_id}/facebook_dataset/bulk_resend
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "tracking_ids": [123, 124, 125]
}
```

#### Resend single conversion
```http
POST /api/v1/accounts/{account_id}/facebook_dataset/{tracking_id}/resend_conversion
Authorization: Bearer {api_token}
```

## Database Schema

### facebook_ads_trackings table
```sql
- id: Primary key
- conversation_id: Link to conversation
- message_id: Link to first message (optional)
- contact_id: Link to contact
- inbox_id: Link to inbox
- account_id: Link to account
- ref_parameter: Ref từ ads
- referral_source: Nguồn (ADS, SHORTLINK, etc.)
- referral_type: Loại referral
- ad_id: Facebook Ad ID
- campaign_id: Facebook Campaign ID
- adset_id: Facebook Adset ID
- ad_title: Tiêu đề quảng cáo
- ad_photo_url: URL ảnh quảng cáo
- ad_video_url: URL video quảng cáo
- raw_referral_data: Raw data từ webhook
- conversion_sent: Đã gửi conversion chưa
- conversion_sent_at: Thời gian gửi conversion
- conversion_response: Response từ Facebook
- event_name: Tên event
- event_value: Giá trị event
- currency: Tiền tệ
- created_at, updated_at: Timestamps
```

## Troubleshooting

### 1. Không nhận được referral events
- Kiểm tra webhook subscription có bao gồm `messaging_referrals`
- Verify webhook URL đang hoạt động
- Kiểm tra Facebook App permissions

### 2. Conversion events không gửi được
- Kiểm tra Conversions API Access Token
- Verify Pixel ID đúng
- Kiểm tra logs trong Chatwoot
- Test connection trong settings

### 3. Tracking data không chính xác
- Kiểm tra ref parameter trong ads URL
- Verify webhook payload format
- Kiểm tra database records

## 📊 Tối Ưu Hóa Ads với Custom Events

### 1. Gửi Custom Events qua API

#### Tạo Custom Event cho Business Logic
```javascript
// JavaScript example - gửi event khi khách hàng qualified
fetch('/api/v1/accounts/{account_id}/facebook_dataset/{tracking_id}/custom_event', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer {api_token}',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    event_name: 'QualifiedLead',
    event_value: 75,
    currency: 'USD'
  })
});
```

#### Gửi Purchase Event
```javascript
// Khi khách hàng mua hàng thành công
fetch('/api/v1/accounts/{account_id}/facebook_dataset/{tracking_id}/custom_event', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer {api_token}',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    event_name: 'Purchase',
    event_value: 299.99,
    currency: 'USD',
    custom_data: {
      content_name: 'Premium Package',
      content_category: 'subscription',
      num_items: 1
    }
  })
});
```

### 2. Webhook Integration cho External Systems

#### Nhận Webhook khi có Tracking mới
```http
POST https://your-system.com/webhooks/facebook-tracking
Content-Type: application/json

{
  "event": "facebook_tracking_created",
  "data": {
    "tracking_id": 123,
    "ref_parameter": "campaign_leadgen_value_25",
    "contact_id": 456,
    "conversation_id": 789,
    "ad_id": "23847656340570",
    "campaign_id": "23847656340569",
    "created_at": "2024-01-15T10:25:00Z"
  }
}
```

#### Cấu hình Webhook trong Chatwoot
```http
POST /api/v1/accounts/{account_id}/webhooks
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "webhook": {
    "inbox_id": 123,
    "webhook_url": "https://your-system.com/webhooks/facebook-tracking",
    "webhook_type": "facebook_tracking"
  }
}
```

### 3. CRM Integration Examples

#### Salesforce Integration
```javascript
// Khi có lead mới từ Facebook ads
async function syncToSalesforce(trackingData) {
  const lead = {
    FirstName: trackingData.contact_name,
    Email: trackingData.contact_email,
    LeadSource: 'Facebook Ads',
    Campaign: trackingData.campaign_id,
    Ad_ID__c: trackingData.ad_id,
    Ref_Parameter__c: trackingData.ref_parameter,
    Event_Value__c: trackingData.event_value
  };

  // Gửi về Salesforce
  await salesforce.sobject('Lead').create(lead);

  // Gửi qualified event về Facebook
  await sendCustomEvent(trackingData.tracking_id, 'QualifiedLead', 50);
}
```

#### HubSpot Integration
```javascript
// Sync với HubSpot và gửi event về Facebook
async function syncToHubSpot(trackingData) {
  const contact = {
    properties: {
      email: trackingData.contact_email,
      firstname: trackingData.contact_name,
      hs_lead_status: 'NEW',
      facebook_ad_id: trackingData.ad_id,
      facebook_campaign_id: trackingData.campaign_id,
      lead_source: 'Facebook Ads'
    }
  };

  await hubspot.crm.contacts.basicApi.create(contact);

  // Gửi event về Facebook
  await sendCustomEvent(trackingData.tracking_id, 'Contact', 25);
}
```

## 🎯 Best Practices cho Tối Ưu Ads

### 1. Event Strategy theo Customer Journey

#### Funnel Events
```
1. Lead (Tin nhắn đầu tiên) → Value: $25
2. QualifiedLead (Sau khi qualify) → Value: $50
3. Opportunity (Thành prospect) → Value: $100
4. Purchase (Mua hàng) → Value: $actual_amount
```

#### Implementation
```javascript
// Tự động gửi events theo customer journey
const eventStrategy = {
  'message_received': { event: 'Lead', value: 25 },
  'contact_qualified': { event: 'QualifiedLead', value: 50 },
  'demo_scheduled': { event: 'Schedule', value: 75 },
  'proposal_sent': { event: 'Opportunity', value: 100 },
  'deal_closed': { event: 'Purchase', value: 'actual_amount' }
};
```

### 2. Dynamic Event Values

#### Theo Product Category
```javascript
const eventValues = {
  'basic_plan': 29,
  'premium_plan': 99,
  'enterprise_plan': 299,
  'consultation': 150,
  'course': 199
};

// Tự động set value dựa trên product
function getEventValue(refParameter) {
  if (refParameter.includes('basic')) return eventValues.basic_plan;
  if (refParameter.includes('premium')) return eventValues.premium_plan;
  if (refParameter.includes('enterprise')) return eventValues.enterprise_plan;
  return 25; // default
}
```

### 3. A/B Testing Events

#### Test Different Event Names
```
Campaign A: event_name = "Lead", value = 25
Campaign B: event_name = "Contact", value = 25
Campaign C: event_name = "InitiateCheckout", value = 25
```

#### Test Different Values
```
Campaign A: event_name = "Lead", value = 10
Campaign B: event_name = "Lead", value = 25
Campaign C: event_name = "Lead", value = 50
```

### 4. Ref Parameter Best Practices

#### Structured Naming
```
{campaign_type}_{product}_{value}_{audience}_{variant}

Examples:
- leadgen_basic_25_young_a
- sales_premium_99_business_b
- retarget_enterprise_299_existing_c
```

#### UTM-style Parameters
```
campaign_leadgen_source_facebook_medium_ads_content_special_offer
```

### 5. Monitoring & Optimization

#### Key Metrics to Track
```javascript
const kpis = {
  cost_per_lead: 'Ad Spend / Total Leads',
  conversion_rate: 'Conversions Sent / Total Trackings',
  roas: 'Revenue / Ad Spend',
  lead_quality: 'Qualified Leads / Total Leads'
};
```

#### Automated Alerts
```javascript
// Set up alerts cho performance issues
if (conversionRate < 90) {
  alert('Low conversion rate detected');
}

if (costPerLead > targetCPL * 1.5) {
  alert('Cost per lead too high');
}
```

### 6. Privacy & Compliance

#### GDPR Compliance
- Chỉ gửi events cho users đã consent
- Implement data retention policies
- Provide opt-out mechanisms

#### Data Minimization
```javascript
// Chỉ gửi data cần thiết
const minimalEventData = {
  event_name: 'Lead',
  event_time: timestamp,
  action_source: 'chat',
  user_data: {
    external_id: hashedContactId, // Hash thay vì raw ID
    // Không gửi email, phone trừ khi cần thiết
  },
  custom_data: {
    value: eventValue,
    currency: 'USD'
  }
};
```

## Monitoring & Analytics

### 1. Key Metrics
- Total trackings vs conversions sent
- Conversion rates by source
- Top performing ads
- Daily tracking trends

### 2. Alerts
- Failed conversion sends
- High error rates
- Missing referral data

### 3. Optimization
- A/B test different ref parameters
- Optimize ad copy based on tracking data
- Adjust event values based on performance

## 🚀 Quick Start Guide

### 1. Setup Facebook App (5 phút)
```bash
1. Tạo Facebook App tại developers.facebook.com
2. Thêm Messenger Platform product
3. Subscribe webhook cho messaging_referrals
4. Tạo Facebook Pixel
5. Generate Conversions API Access Token
```

### 2. Cấu hình Chatwoot (3 phút)
```bash
1. Vào Settings > Inboxes > [Facebook Inbox] > Facebook Dataset
2. Bật "Enable Facebook Dataset Tracking"
3. Nhập Pixel ID và Access Token
4. Set Default Event Name = "Lead", Value = 25
5. Test Connection
```

### 3. Tạo Facebook Ads (2 phút)
```bash
1. Tạo ads với URL: https://m.me/YOUR_PAGE_ID?ref=campaign_test_value_25
2. Set Conversion Goal = "Conversions"
3. Choose Pixel Event = "Lead"
4. Launch campaign
```

### 4. Verify Tracking (1 phút)
```bash
1. Click vào ads từ mobile
2. Gửi tin nhắn test
3. Kiểm tra Facebook Events Manager
4. Xem tracking data trong Chatwoot Analytics
```

## 📞 Support & Troubleshooting

### Common Issues & Solutions

#### 1. Không nhận được referral events
```bash
✅ Check: Webhook subscription includes messaging_referrals
✅ Check: Facebook App permissions
✅ Check: Webhook URL responding 200 OK
✅ Check: Page access token valid
```

#### 2. Conversion events không gửi được
```bash
✅ Check: Conversions API Access Token valid
✅ Check: Pixel ID correct
✅ Check: Test connection passes
✅ Check: Auto send conversions enabled
```

#### 3. Tracking data không chính xác
```bash
✅ Check: Ref parameter in ads URL
✅ Check: Webhook payload format
✅ Check: Database records created
✅ Check: Event values configured correctly
```

### Debug Commands
```bash
# Check webhook logs
tail -f log/production.log | grep "Facebook"

# Test Facebook API connection
curl -X POST "https://graph.facebook.com/v18.0/{pixel_id}/events" \
  -H "Content-Type: application/json" \
  -d '{
    "data": [{"event_name": "Test", "event_time": 1640995200, "action_source": "chat"}],
    "access_token": "YOUR_TOKEN"
  }'

# Check database records
rails console
> FacebookAdsTracking.recent.limit(10)
```

### Performance Monitoring
```bash
# Key metrics to monitor
- Conversion rate > 95%
- API response time < 2s
- Error rate < 1%
- Daily tracking volume
```

### Contact Support
Khi cần hỗ trợ, cung cấp:
1. **Error logs** từ Chatwoot
2. **Facebook App ID** và Pixel ID
3. **Webhook payload** sample
4. **Steps to reproduce** issue
5. **Expected vs actual** behavior

**Support channels:**
- 📧 Email: support@mooly.vn
- 💬 Chat: https://mooly.vn/support
- 📚 Docs: https://docs.mooly.vn/facebook-dataset
