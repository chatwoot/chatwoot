module Enterprise::Api::V1::Accounts::InboxesController
  extend ActiveSupport::Concern

  def inbox_attributes
    super + ee_inbox_attributes
  end

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

  # Toggles only the inbound-calls flag in provider_config. Saved with validate: false
  # so WhatsApp's remote credential re-check (validate_provider_config) can't reject a
  # simple toggle, mirroring enable_voice_calling!. Voice support (WhatsApp calling or
  # Twilio voice) is guarded inline by ensure_inbound_calls_supported.
  def set_inbound_calls
    return unless ensure_inbound_calls_supported

    channel = @inbox.channel
    channel.provider_config = (channel.provider_config || {}).merge(
      'inbound_calls_enabled' => ActiveModel::Type::Boolean.new.cast(params[:inbound_calls_enabled])
    )
    channel.save!(validate: false)
    @inbox.update_account_cache # bump inbox cache key so the cached inbox list refetches the new flag
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def ee_inbox_attributes
    [auto_assignment_config: [:max_assignment_limit]]
  end

  private

  def ensure_whatsapp_calling_supported
    channel = @inbox.channel
    return true if channel.is_a?(Channel::Whatsapp) && channel.voice_calling_supported?

    render_could_not_create_error('Inbox does not support WhatsApp calling')
    false
  end

  # Inbound calls can be toggled on any voice-enabled inbox (WhatsApp calling or Twilio voice).
  def ensure_inbound_calls_supported
    return true if @inbox.channel.try(:voice_enabled?)

    render_could_not_create_error('Inbox does not support calling')
    false
  end

  def get_channel_attributes(channel_type)
    attrs = super
    attrs += [:voice_enabled, :api_key_sid, :api_key_secret] if channel_type == 'Channel::TwilioSms' && @inbox&.channel&.medium == 'sms'
    attrs
  end
end
