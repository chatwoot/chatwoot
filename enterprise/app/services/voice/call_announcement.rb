# What callers hear in one situation: as a greeting, the missed-call message when nobody answers or
# nobody is online, or the out-of-hours message when the inbox is closed. The text lives in the
# channel's provider_config and Captain records it when available. Twilio reads the text in the
# account's language when no saved audio exists. The greeting can be off; the missed-call message
# is always on and falls back to a default text; an empty out-of-hours message is the missed-call
# message.
class Voice::CallAnnouncement
  MESSAGE_MAX_LENGTH = 1000
  KINDS = {
    'greeting' => { enabled: 'call_greeting_enabled', message: 'call_greeting_message', audio: :call_greeting_audio },
    'unanswered' => { message: 'unanswered_call_message', audio: :unanswered_call_audio, default: 'inbox.call_announcements.default_unanswered' },
    'out_of_hours' => { message: 'out_of_hours_call_message', audio: :out_of_hours_call_audio, same_as: 'unanswered' }
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
    return true unless enabled_key

    channel.provider_config[enabled_key] == true
  end

  # The text the inbox saved for this announcement, empty when it uses the default or another one
  def saved_message
    channel.provider_config[message_key]
  end

  def message
    return saved_message if saved_message.present?
    return same_as.message if same_as
    return saved_message unless default_key

    I18n.with_locale(inbox.account.locale) { I18n.t(default_key) }
  end

  def audio
    inbox.public_send(KINDS.fetch(kind)[:audio])
  end

  def speak(twiml)
    return same_as.speak(twiml) if same_as && saved_message.blank?
    return twiml.play(url: Rails.application.routes.url_helpers.rails_blob_url(audio)) if audio.attached?

    twiml.say(message: message, language: language)
  end

  # Regenerates the audio when the text changed; `config` carries settings saved in the same write
  def save!(enabled:, message:, config: {})
    changed = message != self.message
    generated = generated_audio(enabled, message, changed)

    channel.with_lock do
      changed = message != self.message
      inbox.reload
      # Register the attachment change before the channel touches a second Inbox instance.
      if generated
        audio.attach(io: StringIO.new(generated), filename: "#{kind.dasherize}-#{inbox.id}.mp3", content_type: 'audio/mpeg')
      elsif changed
        audio.purge_later
      end
      settings = { message_key => message }
      settings[enabled_key] = enabled if enabled_key
      channel.update!(provider_config: channel.provider_config.merge(config, settings))
    end
  end

  private

  def channel
    inbox.channel
  end

  def enabled_key
    KINDS.fetch(kind)[:enabled]
  end

  def default_key
    KINDS.fetch(kind)[:default]
  end

  # The announcement this one plays while its own text is empty
  def same_as
    name = KINDS.fetch(kind)[:same_as]
    @same_as ||= self.class.new(inbox, name) if name
  end

  def message_key
    KINDS.fetch(kind)[:message]
  end

  def language
    locale = inbox.account.locale.tr('_', '-')
    LANGUAGES.fetch(locale) { LANGUAGES.fetch(locale.split('-').first, 'en-US') }
  end

  def generated_audio(enabled, message, changed)
    return unless enabled && message.present? && Llm::TextToSpeechService.available_for?(inbox.account)
    return unless changed || !audio.attached?

    Llm::TextToSpeechService.new(text: message, account: inbox.account).perform
  rescue Faraday::Error
    raise CustomExceptions::AnnouncementGenerationFailed.new({})
  end
end
