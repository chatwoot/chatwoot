# frozen_string_literal: true

class Integrations::Facebook::MessageParser
  def initialize(response_json)
    @response = JSON.parse(response_json)
  end

  def sender_id
    @response['messaging']['sender']['id']
  end

  def recipient_id
    @response['messaging']['recipient']['id']
  end

  def time_stamp
    @response['messaging']['timestamp']
  end

  def content
    @response['messaging']['message']['text']
  end

  def sequence
    @response['messaging']['message']['seq']
  end

  def attachments
    @response['messaging']['message']['attachments']
  end

  def identifier
    @response['messaging']['message']['mid']
  end

  def echo?
    @response['messaging']['message']['is_echo']
  end

  # TODO : i don't think the payload contains app_id. if not remove
  def app_id
    @response['messaging']['message']['app_id']
  end

  # TODO : does this work ?
  def sent_from_chatwoot_app?
    app_id && app_id == ENV['FB_APP_ID'].to_i
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
