class Captain::Documents::ChunkRerankerService
  include Integrations::LlmInstrumentation

  DEFAULT_MODEL = 'rerank-v4.0-pro'.freeze
  DEFAULT_ENDPOINT = 'https://api.cohere.com/v2/rerank'.freeze
  MAX_RERANK_TEXT_CHARACTERS = 1_200

  def initialize(account_id:)
    @account_id = account_id
    @model = resolve_model
    @api_key = InstallationConfig.find_by(name: 'CAPTAIN_COHERE_API_KEY')&.value.to_s
    @endpoint =
      InstallationConfig.find_by(name: 'CAPTAIN_COHERE_RERANK_ENDPOINT')&.value.to_s.presence ||
      InstallationConfig.find_by(name: 'CAPTAIN_COHERE_API_BASE')&.value.to_s.presence ||
      DEFAULT_ENDPOINT
  end

  def rerank(query:, candidates:, limit:)
    return candidates.first(limit) if candidates.blank?
    return candidates.first(limit) if @api_key.blank?

    reranked_indices = fetch_reranked_indices(query, candidates)
    return candidates.first(limit) if reranked_indices.blank?

    reranked_chunks = reranked_indices.filter_map { |index| candidates[index] }
    remaining_chunks = candidates.reject { |chunk| reranked_chunks.include?(chunk) }
    (reranked_chunks + remaining_chunks).first(limit)
  rescue StandardError => e
    Rails.logger.warn "Chunk reranker failed: #{e.message}"
    candidates.first(limit)
  end

  private

  def reranker_text(chunk)
    [chunk.context, chunk.content]
      .compact
      .join("\n\n")
      .squish
      .first(MAX_RERANK_TEXT_CHARACTERS)
  end

  def instrumentation_params(query, documents)
    {
      span_name: 'llm.captain.chunk_rerank',
      model: @model,
      feature_name: 'chunk_rerank',
      account_id: @account_id,
      messages: [
        { role: 'user', content: { query: query, document_count: documents.size }.to_json }
      ]
    }
  end

  def resolve_model
    InstallationConfig.find_by(name: 'CAPTAIN_CHUNK_RERANK_MODEL')&.value.presence || DEFAULT_MODEL
  end

  def fetch_reranked_indices(query, candidates)
    documents = candidates.map { |chunk| reranker_text(chunk) }
    response_payload = instrument_llm_call(instrumentation_params(query, documents)) do
      cohere_rerank(query, documents)
    end

    parse_reranked_indices(response_payload, candidates.size)
  end

  def cohere_rerank(query, documents)
    response = HTTParty.post(
      @endpoint,
      body: {
        model: @model,
        query: query,
        documents: documents,
        top_n: documents.size
      }.to_json,
      headers: cohere_headers
    )

    raise "Cohere rerank request failed with status #{response.code}" unless response.success?

    parsed = response.parsed_response
    raise 'Cohere rerank response is invalid' unless parsed.is_a?(Hash)

    parsed
  end

  def parse_reranked_indices(payload, candidate_count)
    results = payload['results']
    return [] unless results.is_a?(Array)

    results
      .filter_map do |result|
        index = Integer(result['index'], exception: false)
        next nil if index.blank?
        next nil if index.negative? || index >= candidate_count

        index
      end
      .uniq
  end

  def cohere_headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end
end
