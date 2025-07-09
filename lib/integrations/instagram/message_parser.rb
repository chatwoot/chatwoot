# frozen_string_literal: true

class Integrations::Instagram::MessageParser
  def initialize(response_json)
    @response = response_json.is_a?(String) ? JSON.parse(response_json) : response_json
    @messaging = @response['messaging'] || @response['standby']
  end

  def sender_id
    @messaging.dig('sender', 'id')
  end

  def recipient_id
    @messaging.dig('recipient', 'id')
  end

  def sender_name
    # Instagram không cung cấp tên trong webhook, sẽ được lấy từ Graph API sau
    nil
  end

  def params
    @messaging
  end

  def time_stamp
    @messaging['timestamp']
  end

  def content
    # Nếu là postback message, lấy title từ postback
    return @messaging.dig('postback', 'title') if postback?

    @messaging.dig('message', 'text')
  end

  def sequence
    @messaging.dig('message', 'seq')
  end

  def attachments
    @messaging.dig('message', 'attachments')
  end

  def identifier
    return @messaging.dig('postback', 'mid') if postback?

    @messaging.dig('message', 'mid')
  end

  def delivery
    @messaging['delivery']
  end

  def read
    @messaging['read']
  end

  def read_watermark
    read&.dig('watermark')
  end

  def delivery_watermark
    delivery&.dig('watermark')
  end

  def echo?
    @messaging.dig('message', 'is_echo')
  end

  # Thêm phương thức kiểm tra postback
  def postback?
    @messaging['postback'].present?
  end

  # Lấy payload từ postback
  def postback_payload
    @messaging.dig('postback', 'payload')
  end

  def app_id
    @messaging.dig('message', 'app_id')
  end

  def sent_from_chatwoot_app?
    app_id && app_id == GlobalConfigService.load('FB_APP_ID', '').to_i
  end

  def in_reply_to_external_id
    @messaging.dig('message', 'reply_to', 'mid')
  end

  # Thêm hỗ trợ messaging_referrals để track nguồn từ Instagram ads
  def referral?
    @messaging['referral'].present?
  end

  def referral_ref
    @messaging.dig('referral', 'ref')
  end

  def referral_source
    @messaging.dig('referral', 'source')
  end

  def referral_type
    @messaging.dig('referral', 'type')
  end

  def referral_ad_id
    @messaging.dig('referral', 'ad_id')
  end

  def referral_ads_context_data
    @messaging.dig('referral', 'ads_context_data')
  end

  # Lấy campaign_id từ referral data (Instagram API v22+ có thể cung cấp trực tiếp)
  def referral_campaign_id
    # Thử lấy từ nhiều vị trí khác nhau trong payload
    campaign_id = @messaging.dig('referral', 'campaign_id') ||
                  @messaging.dig('referral', 'ads_context_data', 'campaign_id') ||
                  extract_utm_parameter('utm_campaign') ||
                  extract_fbclid_parameter('campaign_id')

    Rails.logger.info("Instagram extracted campaign_id: #{campaign_id}") if campaign_id
    campaign_id
  end

  # Lấy adset_id từ referral data (Instagram API v22+ có thể cung cấp trực tiếp)
  def referral_adset_id
    # Thử lấy từ nhiều vị trí khác nhau trong payload
    adset_id = @messaging.dig('referral', 'adset_id') ||
               @messaging.dig('referral', 'ads_context_data', 'adset_id') ||
               extract_utm_parameter('utm_adset') ||
               extract_fbclid_parameter('adset_id')

    Rails.logger.info("Instagram extracted adset_id: #{adset_id}") if adset_id
    adset_id
  end

  # Lấy toàn bộ referral data để lưu trữ
  def referral_data
    return nil unless referral?

    # Bao gồm cả messaging data để có thể extract thêm thông tin sau này
    {
      'referral' => @messaging['referral'],
      'messaging_timestamp' => @messaging['timestamp'],
      'sender_id' => @messaging.dig('sender', 'id'),
      'recipient_id' => @messaging.dig('recipient', 'id'),
      'platform' => 'instagram'
    }
  end

  private

  # Extract UTM parameters from referral ref
  def extract_utm_parameter(param_name)
    ref = referral_ref
    return nil unless ref.present?

    # Parse UTM parameters from ref string
    uri = URI.parse("http://example.com?#{ref}") rescue nil
    return nil unless uri

    params = URI.decode_www_form(uri.query || '').to_h
    params[param_name]
  end

  # Extract parameters from fbclid or similar tracking parameters
  def extract_fbclid_parameter(param_name)
    ref = referral_ref
    return nil unless ref.present?

    # Look for specific parameter patterns in ref
    case param_name
    when 'campaign_id'
      ref.match(/campaign[_\-]?id[=:]([^&]+)/i)&.captures&.first
    when 'adset_id'
      ref.match(/adset[_\-]?id[=:]([^&]+)/i)&.captures&.first
    end
  end
end

# Sample Instagram Referral Response (from ads) - Updated for Instagram API v22+
# {
#   "sender":{
#     "id":"INSTAGRAM_USER_ID"
#   },
#   "recipient":{
#     "id":"INSTAGRAM_BUSINESS_ID"
#   },
#   "timestamp":1458692752478,
#   "referral":{
#     "ref":"REF_DATA_IN_INSTAGRAM_LINK",
#     "source":"ADS",
#     "type":"OPEN_THREAD",
#     "ad_id":"AD_ID",
#     "campaign_id":"CAMPAIGN_ID",  // Có thể có trong API v22+
#     "adset_id":"ADSET_ID",        // Có thể có trong API v22+
#     "ads_context_data":{
#       "ad_title":"AD_TITLE",
#       "photo_url":"AD_PHOTO_URL",
#       "video_url":"AD_VIDEO_URL",
#       "campaign_id":"CAMPAIGN_ID", // Fallback location
#       "adset_id":"ADSET_ID"        // Fallback location
#     }
#   }
# }
