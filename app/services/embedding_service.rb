# frozen_string_literal: true

# [whisker] Generates embeddings using BYOR providers or system OpenAI config.
# Falls back to a simple hash-based embedding when no provider is available.
class EmbeddingService
  EMBEDDING_MODEL = 'text-embedding-3-small'.freeze
  EMBEDDING_DIMENSIONS = 1536

  pattr_initialize [:text!]

  def generate
    generate_via_byor || generate_fallback_embedding
  end

  private

  def generate_via_byor
    account = find_account
    return nil unless account

    resolver = WhiskerAi::ProviderResolver.new(account: account, feature: :embedding)
    config = resolver.resolve_with_fallback
    return nil unless config

    call_embedding_api(config)
  rescue StandardError => e
    Rails.logger.error("[WhiskerAI] Embedding generation failed: #{e.message}")
    nil
  end

  def call_embedding_api(config)
    client = Faraday.new(url: config[:api_base]) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end

    response = client.post('/embeddings') do |req|
      req.headers['Authorization'] = "Bearer #{config[:api_key]}"
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        model: config[:model] || EMBEDDING_MODEL,
        input: text.truncate(8000)
      }
    end

    return nil unless response.success?

    response.body['data']&.first&.dig('embedding')
  end

  def find_account
    # Context: called from KnowledgeBase#before_save which has account_id
    Account.find_by(id: @account_id) if @account_id.present?
  end

  # Deterministic fallback: consistent hash-based vector when no API is available
  # Not as good as real embeddings, but functional for self-hosted without API keys
  def generate_fallback_embedding
    hash = Digest::SHA256.hexdigest(text.downcase.strip)
    vector = Array.new(EMBEDDING_DIMENSIONS, 0.0)

    hash.scan(/../).each_with_index do |hex, i|
      next if i >= EMBEDDING_DIMENSIONS

      vector[i] = hex.to_i(16) / 255.0
    end

    # Normalize
    magnitude = Math.sqrt(vector.sum { |v| v**2 })
    return vector if magnitude.zero?

    vector.map { |v| v / magnitude }
  end
end
