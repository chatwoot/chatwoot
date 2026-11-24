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
      turn_on_callback_permission
    end
  end

  def update_callback_permission!(enabled)
    with_call_settings_lock { apply_callback_permission!(enabled) }
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

  private

  # Meta first, so the saved flag never claims a setting Meta refused
  def apply_callback_permission!(enabled)
    provider_service.update_callback_permission_status(enabled ? 'ENABLED' : 'DISABLED')
    self.provider_config = provider_config.merge('callback_permission_enabled' => enabled)
    save!(validate: false)
  end

  # On by default unless an admin turned it off; if Meta refuses, calling still turns on and the setting shows off
  def turn_on_callback_permission
    return if provider_config['callback_permission_enabled'] == false

    apply_callback_permission!(true)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP CALL] callback permission not turned on for channel #{id}: #{e.message}"
  end
end
