module Concerns::WhatsappCallingActions
  def enable_whatsapp_calling
    return unless ensure_whatsapp_calling_supported

    @inbox.channel.enable_voice_calling!
    head :ok
  rescue ActiveRecord::RecordInvalid
    raise
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

  def set_whatsapp_callback_permission
    return unless ensure_whatsapp_calling_supported

    @inbox.channel.update_callback_permission!(ActiveModel::Type::Boolean.new.cast(params[:enabled]))
    @inbox.update_account_cache
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def fetch_health_data
    health = super
    return health unless whatsapp_cloud_channel? && @inbox.channel.voice_enabled?

    health.merge(calling: Whatsapp::CallingHealthService.new(channel: @inbox.channel).perform)
  end

  def update_inbox_working_hours
    super
    return unless @inbox.whatsapp? && call_hours_inputs_changed?

    channel = @inbox.channel
    channel.with_call_settings_lock { channel.apply_call_hours! if channel.business_hours_calls_enabled? && channel.voice_enabled? }
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
