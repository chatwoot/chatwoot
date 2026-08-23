class Captain::MessageLengthLimit
  DEFAULT = 10_000
  INSTAGRAM_LIMIT = 1_000
  INSTAGRAM_DIRECT_MESSAGE = 'instagram_direct_message'.freeze
  TWILIO_LIMITS = {
    'sms' => 320,
    'whatsapp' => 1_600
  }.freeze

  def self.for(conversation)
    return unless conversation

    inbox = conversation.inbox
    return INSTAGRAM_LIMIT if instagram_direct_message?(conversation)
    return TWILIO_LIMITS.fetch(inbox.channel.medium) if inbox.twilio?

    inbox.channel.message_length_limit
  end

  def self.instagram_direct_message?(conversation)
    conversation.additional_attributes['type'] == INSTAGRAM_DIRECT_MESSAGE
  end
end
