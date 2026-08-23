# frozen_string_literal: true

module LlmConstants
  DEFAULT_MODEL = 'openrouter/free'
  DEFAULT_EMBEDDING_MODEL = 'text-embedding-3-small'
  PDF_PROCESSING_MODEL = 'openrouter/free'

  # Fixed dimension of the pgvector embedding columns. pgvector enforces the
  # dimension at write time, so a model emitting a different dimension fails
  # with an opaque DB error unless validated here first.
  EMBEDDING_DIMENSION = 1024

  OPENAI_API_ENDPOINT = 'https://api.openai.com'

  PROVIDER_PREFIXES = {
    'openai' => %w[gpt- o1 o3 o4 text-embedding- whisper- tts-],
    'anthropic' => %w[claude-],
    'google' => %w[gemini-],
    'mistral' => %w[mistral- codestral-],
    'deepseek' => %w[deepseek-]
  }.freeze
end
