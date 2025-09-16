# frozen_string_literal: true

class Integrations::Facebook::MessageParser
  def initialize(response_json)
    @response = JSON.parse(response_json)
  
    # Support both formats:
    # - Wrapped inside "messaging"/"standby" array
    # - Wrapped inside "messaging"/"standby" object (non-standard but sometimes happens)
    # - Directly sent as single event hash (e.g., for testing or broken webhooks)
    @messaging =
      if @response['messaging']&.is_a?(Array)
        @response['messaging'].first
      elsif @response['standby']&.is_a?(Array)
        @response['standby'].first
      elsif @response['messaging']&.is_a?(Hash)
        @response['messaging']
      elsif @response['standby']&.is_a?(Hash)
        @response['standby']
      else
        @response
      end
  end
  

  def message
    @messaging["message"]
  end  

  def read
    @messaging["read"]
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

  def raw
    @response
  end
end
