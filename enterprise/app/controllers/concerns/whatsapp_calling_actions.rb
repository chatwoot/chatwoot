# Turning WhatsApp calling on or off for an inbox, and keeping its call hours at Meta in step with
# the inbox's business hours when inbox settings are saved
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

  # Business hours, the timezone, or whether hours are on may have changed the call hours Meta
  # should hold. Checked once everything in the save is written, and only when the save succeeded.
  def update
    super
    return if performed? || !@inbox.whatsapp?

    @inbox.channel.reload.schedule_call_hours_sync
  end

  private

  # Runs inside the inbox save's transaction once the hours are written, so a week with no open day
  # rolls the whole save back with 422 while business hours apply to WhatsApp calls
  def update_inbox_working_hours
    super
    return unless @inbox.whatsapp? && (params.key?(:working_hours) || @inbox.saved_change_to_working_hours_enabled?)

    channel = @inbox.channel.reload
    channel.call_hours_schedule_valid
    raise ActiveRecord::RecordInvalid, channel if channel.errors.any?
  end

  def ensure_whatsapp_calling_supported
    channel = @inbox.channel
    return true if channel.is_a?(Channel::Whatsapp) && channel.voice_calling_supported?

    render_could_not_create_error('Inbox does not support WhatsApp calling')
    false
  end
end
