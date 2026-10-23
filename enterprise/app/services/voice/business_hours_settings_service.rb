class Voice::BusinessHoursSettingsService
  MESSAGE_MAX_LENGTH = 1000

  pattr_initialize [:inbox!, :enabled!, :message!]

  def perform
    channel = inbox.channel
    changed = message != channel.out_of_hours_call_message
    audio = recorded_audio(changed)

    channel.with_lock do
      changed = message != channel.out_of_hours_call_message
      inbox.reload
      # Register the attachment change before the channel touches a second Inbox instance.
      if audio
        inbox.out_of_hours_call_audio.attach(io: StringIO.new(audio), filename: "out-of-hours-#{inbox.id}.mp3", content_type: 'audio/mpeg')
      elsif changed
        inbox.out_of_hours_call_audio.purge_later
      end
      channel.update!(provider_config: channel.provider_config.merge(
        'business_hours_calls_enabled' => enabled,
        'out_of_hours_call_message' => message
      ))
    end
  end

  private

  def recorded_audio(changed)
    return unless enabled && Llm::TextToSpeechService.available_for?(inbox.account)
    return unless changed || !inbox.out_of_hours_call_audio.attached?

    Llm::TextToSpeechService.new(text: message, account: inbox.account).perform
  end
end
