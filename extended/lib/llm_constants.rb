# frozen_string_literal: true

module LlmConstants
  # OpenAI provider defaults
  OPENAI = {
    endpoint: 'https://api.openai.com',
    chat_model: 'gpt-4o-mini',
    embedding_model: 'text-embedding-3-small',
    transcription_model: 'whisper-1',
    pdf_processing_model: 'gpt-4o-mini'
  }.freeze

  # Google Gemini provider defaults
  GEMINI = {
    endpoint: 'https://generativelanguage.googleapis.com',
    chat_model: 'gemini-2.5-flash',
    embedding_model: 'text-embedding-004',
    transcription_model: 'gemini-2.5-flash',
    pdf_processing_model: 'gemini-2.5-pro'
  }.freeze

  # Get the current configured provider
  # @return [String] The provider name ('openai', 'gemini', etc.)
  def self.current_provider
    @current_provider ||= InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value
  end

  # Reset cached provider (useful for tests)
  def self.reset_provider_cache!
    @current_provider = nil
  end

  # Get defaults for the current provider (cached)
  # @return [Hash] Provider-specific defaults
  def self.current_defaults
    defaults_for(current_provider)
  end

  # Get defaults for a specific provider
  # @param provider [String, Symbol] The provider name ('openai', 'gemini')
  # @return [Hash] Provider-specific defaults
  def self.defaults_for(provider)
    case provider.to_s.downcase
    when 'openai', ''
      OPENAI
    when 'gemini'
      GEMINI
    else
      raise ArgumentError, "Unknown LLM provider: #{provider}. Supported providers: openai, gemini"
    end
  end
end
