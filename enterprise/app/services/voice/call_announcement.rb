# What callers hear in one situation: out of hours, as a greeting, or when nobody answers. The
# text lives in the channel's provider_config and Captain records it when available.
# Twilio reads the text in the account's language when no saved audio exists.
class Voice::CallAnnouncement
  MESSAGE_MAX_LENGTH = 1000
  KINDS = {
    'out_of_hours' => { enabled: 'business_hours_calls_enabled', message: 'out_of_hours_call_message', audio: :out_of_hours_call_audio },
    'greeting' => { enabled: 'call_greeting_enabled', message: 'call_greeting_message', audio: :call_greeting_audio },
    'unanswered' => { enabled: 'unanswered_calls_enabled', message: 'unanswered_call_message', audio: :unanswered_call_audio }
  }.freeze
  # Languages supported by Twilio's basic voices. Other account languages retain the English default.
  LANGUAGES = {
    'en' => 'en-US', 'en-GB' => 'en-GB', 'de' => 'de-DE',
    'es' => 'es-ES', 'fr' => 'fr-FR', 'it' => 'it-IT'
  }.freeze

  attr_reader :inbox, :kind

  def initialize(inbox, kind)
    @inbox = inbox
    @kind = kind.to_s
  end

  def enabled?
    channel.provider_config[enabled_key] == true
  end

  def message
    channel.provider_config[message_key]
  end

  # The recorded audio, for an announcement that has one
  def audio
    name = KINDS.fetch(kind)[:audio]
    inbox.public_send(name) if name
  end

  def speak(twiml)
    return twiml.play(url: Rails.application.routes.url_helpers.rails_blob_url(audio)) if audio&.attached?

    twiml.say(message: message, language: language)
  end

  # Regenerates the audio when the text changed; `config` carries settings saved in the same write
  def save!(enabled:, message:, config: {})
    changed = message != self.message
    generated = generated_audio(enabled, message, changed) if audio

    channel.with_lock do
      changed = message != self.message
      inbox.reload
      # Register the attachment change before the channel touches a second Inbox instance.
      if generated
        audio.attach(io: StringIO.new(generated), filename: "#{kind.dasherize}-#{inbox.id}.mp3", content_type: 'audio/mpeg')
      elsif changed
        audio&.purge_later
      end
      channel.update!(provider_config: channel.provider_config.merge(config, enabled_key => enabled, message_key => message))
    end
  end

  private

  def channel
    inbox.channel
  end

  def enabled_key
    KINDS.fetch(kind)[:enabled]
  end

  def message_key
    KINDS.fetch(kind)[:message]
  end

  def language
    locale = inbox.account.locale.tr('_', '-')
    LANGUAGES.fetch(locale) { LANGUAGES.fetch(locale.split('-').first, 'en-US') }
  end

  def generated_audio(enabled, message, changed)
    return unless enabled && Llm::TextToSpeechService.available_for?(inbox.account)
    return unless changed || !audio.attached?

    Llm::TextToSpeechService.new(text: message, account: inbox.account).perform
  rescue Faraday::Error
    raise CustomExceptions::AnnouncementGenerationFailed.new({})
  end
end
