# frozen_string_literal: true

module Captain::Providers::Gemini::Embeddings
  # TODO: Implement Gemini embeddings using HTTP requests to:
  # POST https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent?key={API_KEY}
  #
  # Key implementation notes:
  # - Gemini text-embedding-004 returns 768 dimensions (vs OpenAI's 1536)
  # - May need to update database schema or use a different embedding model
  # - Request format: { content: { parts: [{ text: '...' }] } }
  def embeddings(parameters:)
    raise NotImplementedError, 'Gemini embeddings is not yet implemented. Please use OpenAI provider.'
  end
end
