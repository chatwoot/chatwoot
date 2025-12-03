# frozen_string_literal: true

module CaptainConfig
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

  # Get complete configuration for the current provider
  # Merges defaults with user-configured values from InstallationConfig
  # @return [Hash] Complete provider configuration
  def self.current_config
    config_for(current_provider)
  end

  # Get complete configuration for a specific provider
  # Merges defaults with user-configured values from InstallationConfig
  # @param provider [String, Symbol] The provider name ('openai', 'gemini')
  # @return [Hash] Complete provider configuration with keys:
  #   - :provider - The provider name
  #   - :api_key - API key from InstallationConfig
  #   - :endpoint - Endpoint (user config or default)
  #   - :chat_model - Chat model (user config or default)
  #   - :embedding_model - Embedding model (user config or default)
  #   - :transcription_model - Transcription model (user config or default)
  #   - :pdf_processing_model - PDF processing model (user config or default)
  #   - :firecrawl_api_key - FireCrawl API key (optional)
  def self.config_for(provider)
    defaults = defaults_for(provider)

    {
      provider: provider.to_s.downcase,
      api_key: InstallationConfig.find_by(name: 'CAPTAIN_LLM_API_KEY')&.value,
      endpoint: InstallationConfig.find_by(name: 'CAPTAIN_LLM_ENDPOINT')&.value.presence || defaults[:endpoint],
      chat_model: InstallationConfig.find_by(name: 'CAPTAIN_LLM_MODEL')&.value.presence || defaults[:chat_model],
      embedding_model: InstallationConfig.find_by(name: 'CAPTAIN_LLM_EMBEDDING_MODEL')&.value.presence || defaults[:embedding_model],
      transcription_model: InstallationConfig.find_by(name: 'CAPTAIN_LLM_TRANSCRIPTION_MODEL')&.value.presence || defaults[:transcription_model],
      pdf_processing_model: defaults[:pdf_processing_model],
      firecrawl_api_key: InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
    }
  end
end
