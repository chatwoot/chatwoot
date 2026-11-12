module Enterprise::Channel::Whatsapp
  include Concerns::CallRecordingSettings
  include Concerns::CallRoutingSettings

  def self.prepended(base)
    base.class_eval do
      validate :call_routing_settings_valid
    end
  end

  # WhatsApp offers a caller nobody answered the option to let the business call back
  def callback_permission_enabled?
    provider_config['callback_permission_enabled'] == true
  end

  # Meta is told first, so the saved flag never claims a setting Meta refused. Saved with
  # validate: false, like the other calling toggles, to skip the remote credential check.
  def update_callback_permission!(enabled)
    provider_service.update_callback_permission_status(enabled ? 'ENABLED' : 'DISABLED')
    self.provider_config = provider_config.merge('callback_permission_enabled' => enabled)
    save!(validate: false)
  end

  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end
end
