# frozen_string_literal: true

class Integrations::Instagram::MessageParser
  def initialize(messaging)
    @messaging = messaging.with_indifferent_access
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

  def attachments
    @messaging.dig('message', 'attachments')
  end

  def identifier
    @messaging.dig('message', 'mid')
  end

  def echo?
    @messaging.dig('message', 'is_echo')
  end

  def in_reply_to_external_id
    @messaging.dig('message', 'reply_to', 'mid')
  end

  def postback_payload
    @messaging.dig('postback', 'payload')
  end

  def postback_title
    @messaging.dig('postback', 'title')
  end

  def quick_reply_payload
    @messaging.dig('message', 'quick_reply', 'payload')
  end

  def postback?
    @messaging.key?('postback')
  end

  def quick_reply?
    @messaging.dig('message', 'quick_reply').present?
  end

  def message?
    @messaging.key?('message')
  end

  def read?
    @messaging.key?('read')
  end
end