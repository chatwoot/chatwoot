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

  def set_inbound_calls
    return unless ensure_calling_supported

    save_call_flags!('inbound_calls_enabled' => ActiveModel::Type::Boolean.new.cast(params[:inbound_calls_enabled]))
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  # Only the flags present in the request are merged, so two admins toggling different settings can't clobber each other.
  def set_call_recording
    return unless ensure_calling_supported

    was_recording = @inbox.channel.recording_enabled?
    flags = params.permit(:recording_enabled, :transcription_enabled).to_h
    save_call_flags!(flags.transform_values { |value| ActiveModel::Type::Boolean.new.cast(value) })
    Voice::RecordingSettingChangeService.new(inbox: @inbox).perform if @inbox.channel.recording_enabled? != was_recording
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

  # Call flags can be toggled on any voice-enabled inbox (WhatsApp calling or Twilio voice).
  def ensure_calling_supported
    return true if @inbox.channel.try(:voice_enabled?)

    render_could_not_create_error('Inbox does not support calling')
    false
  end

  # Flags live in provider_config. The row lock serializes concurrent toggles (each merges only its
  # own keys), and validate: false keeps WhatsApp's remote credential re-check from rejecting a toggle.
  def save_call_flags!(flags)
    channel = @inbox.channel
    channel.with_lock do
      channel.provider_config = channel.provider_config.merge(flags)
      channel.save!(validate: false)
    end
    @inbox.update_account_cache # bump inbox cache key so the cached inbox list refetches the new flags
  end

  def allowed_channel_types
    super + ['voice']
  end

  def channel_type_from_params
    return Channel::TwilioSms if permitted_params[:channel][:type] == 'voice'

    super
  end

  def account_channels_method
    return Current.account.twilio_sms if permitted_params[:channel][:type] == 'voice'

    super
  end

  def create_channel
    return create_voice_channel if permitted_params[:channel][:type] == 'voice'

    super
  end

  def get_channel_attributes(channel_type)
    attrs = super
    attrs += [:voice_enabled, :api_key_sid, :api_key_secret] if channel_type == 'Channel::TwilioSms' && @inbox&.channel&.medium == 'sms'
    attrs
  end

  def create_voice_channel
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?('channel_voice')

    voice_params = params.require(:channel).permit(
      :phone_number, :provider,
      provider_config: [:account_sid, :auth_token, :api_key_sid, :api_key_secret]
    )
    config = voice_params[:provider_config] || {}

    Current.account.twilio_sms.create!(
      phone_number: voice_params[:phone_number],
      account_sid: config[:account_sid],
      auth_token: config[:auth_token],
      api_key_sid: config[:api_key_sid],
      api_key_secret: config[:api_key_secret],
      medium: :sms,
      voice_enabled: true
    )
  end
end
