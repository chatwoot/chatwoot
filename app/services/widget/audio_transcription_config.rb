# Resolves the widget voice-to-text OpenAI configuration from ENV so the
# feature is independent of the (paid) Captain integration. Per-inbox
# availability is controlled by the web widget `voice_recorder` feature flag;
# this only supplies the credentials and model. Falls back to the Captain OpenAI
# installation config for the key and endpoint as a convenience.
module Widget::AudioTranscriptionConfig
  DEFAULT_ENDPOINT = 'https://api.openai.com/'.freeze

  module_function

  def configured?
    api_key.present?
  end

  def api_key
    widget_key = ENV['WIDGET_TRANSCRIPTION_OPENAI_API_KEY'].presence
    return widget_key if widget_key
    # The Captain key belongs to the Captain endpoint, so never send it to a
    # widget-specific host; that setup also needs its own widget key.
    return if ENV['WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT'].present?

    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
  end

  # An explicit model wins, e.g. for a self-hosted OpenAI-compatible server;
  # otherwise use the model Chatwoot routes for audio transcription.
  def model(account)
    ENV['WIDGET_TRANSCRIPTION_OPENAI_MODEL'].presence ||
      Llm::FeatureRouter.resolve(feature: 'audio_transcription', account: account)[:model]
  end

  # Optional text prompt passed to the transcription model to bias recognition
  # towards domain terms, names and spelling (OpenAI's `prompt` field).
  def prompt
    ENV['WIDGET_TRANSCRIPTION_OPENAI_PROMPT'].presence
  end

  # Optional ISO-639-1 language code (e.g. "lt"). When unset the model
  # auto-detects the spoken language.
  def language
    ENV['WIDGET_TRANSCRIPTION_OPENAI_LANGUAGE'].presence
  end

  def endpoint
    raw = ENV['WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT'].presence
    if raw.blank? && ENV['WIDGET_TRANSCRIPTION_OPENAI_API_KEY'].blank?
      raw = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence
    end
    raw ||= DEFAULT_ENDPOINT
    # ruby-openai joins this with "v1/audio/transcriptions", so a trailing
    # slash is required to avoid producing a malformed "...hostv1/..." URL.
    raw.end_with?('/') ? raw : "#{raw}/"
  end
end
