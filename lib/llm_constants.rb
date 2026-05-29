# frozen_string_literal: true

module LlmConstants
  DEFAULT_MODEL = 'gpt-4.1'
  DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small'
  DEFAULT_EMBEDDING_DIMENSIONS = 1536
  PDF_PROCESSING_MODEL = 'gpt-4.1-mini'

  OPENAI_API_ENDPOINT = 'https://api.openai.com'

  PROVIDER_PREFIXES = {
    'openai' => %w[gpt- o1 o3 o4 text-embedding- whisper- tts-],
    'anthropic' => %w[claude-],
    'gemini' => %w[gemini-],
    'mistral' => %w[mistral- codestral-],
    'deepseek' => %w[deepseek-]
  }.freeze
end
