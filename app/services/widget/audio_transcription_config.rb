# Resolves the widget voice-to-text OpenAI configuration from ENV so the
# feature is independent of the (paid) Captain integration. Per-inbox
# availability is controlled by the web widget `voice_recorder` feature flag;
# this only supplies the credentials. Falls back to the Captain OpenAI
# installation config for the key as a convenience.
module Widget
  module AudioTranscriptionConfig
    DEFAULT_MODEL = 'gpt-4o-mini-transcribe'.freeze
    DEFAULT_ENDPOINT = 'https://api.openai.com/'.freeze

    module_function

    def configured?
      api_key.present?
    end

    def api_key
      ENV['WIDGET_TRANSCRIPTION_OPENAI_API_KEY'].presence || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def model
      ENV['WIDGET_TRANSCRIPTION_OPENAI_MODEL'].presence || DEFAULT_MODEL
    end

    def endpoint
      ENV['WIDGET_TRANSCRIPTION_OPENAI_ENDPOINT'].presence || DEFAULT_ENDPOINT
    end
  end
end
