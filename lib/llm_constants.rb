# frozen_string_literal: true

module LlmConstants
  CAPTAIN_LLM_PROVIDER_CONFIG_KEY = 'CAPTAIN_LLM_PROVIDER'
  CAPTAIN_PDF_PROCESSING_MODEL_CONFIG_KEY = 'CAPTAIN_PDF_PROCESSING_MODEL'

  # Fallback when InstallationConfig `CAPTAIN_LLM_PROVIDER` is blank or invalid.
  DEFAULT_CAPTAIN_RUBY_LLM_PROVIDER = :ollama

  DEFAULT_MODEL = 'llama3.1:8b' #'gpt-4.1-mini'
  DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small'
  # Must match `vector(1536)` on `captain_assistant_responses.embedding` and `article_embeddings.embedding`.
  EMBEDDING_VECTOR_DIMENSIONS = 1536
  # Fallback when InstallationConfig `CAPTAIN_PDF_PROCESSING_MODEL` is blank.
  DEFAULT_CAPTAIN_PDF_PROCESSING_MODEL = 'llama3.1:8b'

  OPENAI_API_ENDPOINT = 'https://api.openai.com'

  PROVIDER_PREFIXES = {
    'openai' => %w[gpt- o1 o3 o4 text-embedding- whisper- tts- qwen3-embedding],
    'anthropic' => %w[claude-],
    'google' => %w[gemini-],
    'mistral' => %w[mistral- codestral-],
    'deepseek' => %w[deepseek-]
  }.freeze

  class << self
    # Model for Captain PDF → FAQ extraction (`PaginatedFaqGeneratorService`). Super Admin → Captain.
    def captain_pdf_processing_model
      InstallationConfig.find_by(name: CAPTAIN_PDF_PROCESSING_MODEL_CONFIG_KEY)&.value.presence ||
        DEFAULT_CAPTAIN_PDF_PROCESSING_MODEL
    end

    # Effective RubyLLM provider for Captain (chat, embeddings, Agents). Set via Super Admin → Captain.
    def captain_ruby_llm_provider
      raw = InstallationConfig.find_by(name: CAPTAIN_LLM_PROVIDER_CONFIG_KEY)&.value.to_s.strip.downcase
      return DEFAULT_CAPTAIN_RUBY_LLM_PROVIDER if raw.blank?

      sym = raw.to_sym
      return sym if valid_ruby_llm_provider_slug?(sym)

      Rails.logger.warn(
        "Invalid #{CAPTAIN_LLM_PROVIDER_CONFIG_KEY} #{raw.inspect}, using #{DEFAULT_CAPTAIN_RUBY_LLM_PROVIDER}"
      )
      DEFAULT_CAPTAIN_RUBY_LLM_PROVIDER
    end

    def valid_ruby_llm_provider_slug?(sym)
      return false if sym.blank?

      return true if defined?(RubyLLM::Provider) && RubyLLM::Provider.providers.is_a?(Hash) && RubyLLM::Provider.providers.key?(sym)

      # Before RubyLLM is loaded (e.g. early boot), accept known slugs only.
      %i[
        anthropic bedrock deepseek gemini gpustack mistral ollama openai openrouter perplexity vertexai
      ].include?(sym)
    end
  end
end
