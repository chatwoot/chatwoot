# frozen_string_literal: true

class Integrations::Facebook::MessageParser
  def initialize(response_json)
    @response = JSON.parse(response_json)
    @messaging = @response['messaging'] || @response['standby']
  end

  def sender_id
    @messaging.dig('sender', 'id')
  end

  def recipient_id
    @messaging.dig('recipient', 'id')
  end

  def sender_name
    # Facebook không cung cấp tên trong webhook, sẽ được lấy từ Graph API sau
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

  # TODO : i don't think the payload contains app_id. if not remove
  def app_id
    @messaging.dig('message', 'app_id')
  end

  # TODO : does this work ?
  def sent_from_chatwoot_app?
    app_id && app_id == GlobalConfigService.load('FB_APP_ID', '').to_i
  end

  def in_reply_to_external_id
    @messaging.dig('message', 'reply_to', 'mid')
  end

  # Thêm hỗ trợ messaging_referrals để track nguồn từ ads
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

  # Lấy toàn bộ referral data để lưu trữ
  def referral_data
    return nil unless referral?

    @messaging['referral']
  end
end

# Sample Response
# {
#   "sender":{
#     "id":"USER_ID"
#   },
#   "recipient":{
#     "id":"PAGE_ID"
#   },
#   "timestamp":1458692752478,
#   "message":{
#     "mid":"mid.1457764197618:41d102a3e1ae206a38",
#     "seq":73,
#     "text":"hello, world!",
#     "quick_reply": {
#       "payload": "DEVELOPER_DEFINED_PAYLOAD"
#     }
#   }
# }

# Sample Postback Response
# {
#   "sender":{
#     "id":"USER_ID"
#   },
#   "recipient":{
#     "id":"PAGE_ID"
#   },
#   "timestamp":1458692752478,
#   "postback":{
#     "mid":"mid.1457764197618:41d102a3e1ae206a38",
#     "title":"TITLE-FOR-THE-CTA",
#     "payload":"USER-DEFINED-PAYLOAD"
#   }
# }

# Sample Referral Response (from ads)
# {
#   "sender":{
#     "id":"USER_ID"
#   },
#   "recipient":{
#     "id":"PAGE_ID"
#   },
#   "timestamp":1458692752478,
#   "referral":{
#     "ref":"REF_DATA_IN_M_DOT_ME_PARAM",
#     "source":"SHORTLINK",
#     "type":"OPEN_THREAD",
#     "ad_id":"AD_ID",
#     "ads_context_data":{
#       "ad_title":"AD_TITLE",
#       "photo_url":"AD_PHOTO_URL",
#       "video_url":"AD_VIDEO_URL"
#     }
#   }
# }
