# frozen_string_literal: true

# DEPRECATED: This class uses the legacy OpenAI Ruby gem directly.
# Only used for audio transcription via Whisper API.
# For all other LLM operations, use Aloo's RubyLLM-based services instead.
class LLM::LegacyBaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'

  attr_reader :client, :model

  def initialize
    @client = OpenAI::Client.new(
      access_token: openai_api_key,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def openai_api_key
    # Try Aloo config first, fall back to legacy Captain config for backward compatibility
    InstallationConfig.find_by(name: 'ALOO_OPENAI_API_KEY')&.value ||
      InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
  end

  def uri_base
    'https://api.openai.com/'
  end

  def setup_model
    @model = DEFAULT_MODEL
  end
end
