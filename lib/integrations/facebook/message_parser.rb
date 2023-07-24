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

  def time_stamp
    @messaging['timestamp']
  end

  def content
    @messaging.dig('message', 'text')
  end

  def sequence
    @messaging.dig('message', 'seq')
  end

  def attachments
    @messaging.dig('message', 'attachments')
  end

  def identifier
    @messaging.dig('message', 'mid')
  end

  def echo?
    @messaging.dig('message', 'is_echo')
  end

  # TODO : i don't think the payload contains app_id. if not remove
  def app_id
    @messaging.dig('message', 'app_id')
  end

  # TODO : does this work ?
  def sent_from_chatwoot_app?
    app_id && app_id == GlobalConfigService.load('FB_APP_ID', '').to_i
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
