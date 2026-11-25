module Enterprise::Channel::Whatsapp
  include Concerns::CallRecordingSettings
  include Concerns::CallRoutingSettings
  include Concerns::WhatsappCallHours

  def self.prepended(base)
    base.class_eval do
      validate :call_routing_settings_valid
    end
  end

  def enable_voice_calling!
    with_call_settings_lock do
      apply_call_hours! if business_hours_calls_enabled?
      super
    end
  end

  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end
end
