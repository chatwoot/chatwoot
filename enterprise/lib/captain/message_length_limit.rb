class Captain::MessageLengthLimit
  DEFAULT = 10_000
  INSTAGRAM_DIRECT_MESSAGE = 'instagram_direct_message'.freeze
  CHANNEL_LIMITS = {
    'Channel::FacebookPage' => 2_000,
    'Channel::Instagram' => 1_000,
    'Channel::Line' => 5_000,
    'Channel::Sms' => 320,
    'Channel::Telegram' => 4_096,
    'Channel::Tiktok' => 6_000,
    'Channel::Whatsapp' => 4_096
  }.freeze
  TWILIO_LIMITS = {
    'sms' => 320,
    'whatsapp' => 1_600
  }.freeze

  def self.for(conversation)
    return unless conversation

    inbox = conversation.inbox
    return CHANNEL_LIMITS.fetch('Channel::Instagram') if conversation.additional_attributes['type'] == INSTAGRAM_DIRECT_MESSAGE
    return TWILIO_LIMITS.fetch(inbox.channel.medium) if inbox.twilio?

    CHANNEL_LIMITS.fetch(inbox.channel_type, DEFAULT)
  end
end
