module Enterprise::Channel::Whatsapp
  include Concerns::CallRecordingSettings
  include Concerns::CallRoutingSettings
  include Concerns::WhatsappCallHours

  def self.prepended(base)
    base.class_eval do
      validate :call_routing_settings_valid
      validate :missed_call_message_valid
    end
  end

  def enable_voice_calling!
    with_call_settings_lock do
      apply_call_hours! if business_hours_calls_enabled?
      super
    end
  end

  def missed_call_message_enabled?
    provider_config['missed_call_message_enabled'] == true
  end

  def missed_call_message_valid
    enabled = provider_config['missed_call_message_enabled']
    message = provider_config['missed_call_message']
    valid_message = message.nil? || (message.is_a?(String) && message.length <= Voice::CallAnnouncement::MESSAGE_MAX_LENGTH)
    return if [true, false, nil].include?(enabled) && valid_message

    errors.add(:base, I18n.t('inbox.missed_call_message.invalid', max: Voice::CallAnnouncement::MESSAGE_MAX_LENGTH))
  end

  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end
end
