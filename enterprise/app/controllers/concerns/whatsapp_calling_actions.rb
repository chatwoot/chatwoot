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

  def ensure_whatsapp_calling_supported
    channel = @inbox.channel
    return true if channel.is_a?(Channel::Whatsapp) && channel.voice_calling_supported?

    render_could_not_create_error('Inbox does not support WhatsApp calling')
    false
  end
end
