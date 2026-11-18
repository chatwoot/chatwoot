module Concerns::WhatsappCallingActions
  def enable_whatsapp_calling
    return unless ensure_whatsapp_calling_supported

    @inbox.channel.enable_voice_calling!
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def disable_whatsapp_calling
    return unless ensure_whatsapp_calling_supported

    @inbox.channel.disable_voice_calling!
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def update_inbox_working_hours
    super
    return unless @inbox.whatsapp? && call_hours_inputs_changed?

    channel = @inbox.channel.reload
    hours_were_applied = channel.business_hours_calls_enabled? && @inbox.working_hours_enabled_before_last_save
    channel.apply_call_hours! if hours_were_applied || channel.apply_call_hours?
  end

  def call_hours_inputs_changed?
    params.key?(:working_hours) || @inbox.saved_change_to_timezone? || @inbox.saved_change_to_working_hours_enabled?
  end

  def ensure_whatsapp_calling_supported
    channel = @inbox.channel
    return true if channel.is_a?(Channel::Whatsapp) && channel.voice_calling_supported?

    render_could_not_create_error('Inbox does not support WhatsApp calling')
    false
  end
end
