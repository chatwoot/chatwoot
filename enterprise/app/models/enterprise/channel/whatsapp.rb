module Enterprise::Channel::Whatsapp
  include Concerns::CallRecordingSettings
  include Concerns::CallRoutingSettings
  include Concerns::WhatsappCallHours

  def self.prepended(base)
    base.class_eval do
      validate :call_routing_settings_valid
      # Turning calling on, or changing the permission request message, needs a template for it at Meta
      after_commit :queue_call_permission_template, on: :update, if: :call_permission_template_missing?
    end
  end

  def enable_voice_calling!
    with_call_settings_lock do
      apply_call_hours! if business_hours_calls_enabled?
      super
    end
  end

  def call_permission_template
    Whatsapp::CallPermissionTemplate.new(self)
  end

  def queue_call_permission_template
    Whatsapp::CreateCallPermissionTemplateJob.perform_later(self)
  end

  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end

  private

  def call_permission_template_missing?
    voice_enabled? && !call_permission_template.created?
  end
end
