class Captain::MessageLengthLimit
  DEFAULT = 10_000
  CHANNEL_LIMITS = {
    'Channel::FacebookPage' => 2_000,
    'Channel::Instagram' => 1_000,
    'Channel::Line' => 2_000,
    'Channel::Sms' => 320,
    'Channel::Telegram' => 4_096,
    'Channel::Tiktok' => 6_000,
    'Channel::Whatsapp' => 4_096
  }.freeze
  TWILIO_LIMITS = {
    'sms' => 320,
    'whatsapp' => 1_600
  }.freeze

  def self.for(inbox)
    return unless inbox
    return TWILIO_LIMITS.fetch(inbox.channel.medium) if inbox.twilio?

    CHANNEL_LIMITS.fetch(inbox.channel_type, DEFAULT)
  end
end
