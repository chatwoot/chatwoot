module Enterprise::Channel::Whatsapp
  include Concerns::CallRecordingSettings
  include Concerns::CallRoutingSettings
  include Concerns::WhatsappCallHours

  def self.prepended(base)
    base.class_eval do
      validate :call_routing_settings_valid
    end
  end

  # Business hours edited while calling was off are sent to Meta once it's back on
  def enable_voice_calling!
    super
    schedule_call_hours_sync
  end

  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end
end
