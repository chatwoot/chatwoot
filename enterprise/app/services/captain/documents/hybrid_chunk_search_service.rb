class Captain::Documents::HybridChunkSearchService
  DEFAULT_VECTOR_LIMIT = 10
  DEFAULT_BM25_LIMIT = 10
  DEFAULT_RESULT_LIMIT = 5
  RRF_K = 60

  def initialize(assistant:)
    @assistant = assistant
    @embedding_service = Captain::Llm::EmbeddingService.new(account_id: assistant.account_id)
  end

  def search(query, limit: DEFAULT_RESULT_LIMIT)
    return [] if query.blank?

    vector_results = vector_search(query)
    bm25_results = bm25_search(query)
    rank_results(vector_results, bm25_results, limit)
  end

  private

  def base_scope
    Captain::DocumentChunk
      .where(account_id: @assistant.account_id, assistant_id: @assistant.id)
      .joins(:document)
      .merge(Captain::Document.chunking_status_ready)
      .includes(:document)
  end

  def vector_search(query)
    embedding = @embedding_service.get_embedding(query)
    return [] if embedding.blank?

    base_scope
      .all
      .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      .limit(DEFAULT_VECTOR_LIMIT)
      .to_a
  end

  def bm25_search(query)
    scope = base_scope
    quoted_query = ActiveRecord::Base.connection.quote(query)
    text_expression = "to_tsvector('english', coalesce(captain_document_chunks.context, '') || ' ' || captain_document_chunks.content)"

    scope
      .where(Arel.sql("#{text_expression} @@ plainto_tsquery('english', #{quoted_query})"))
      .order(Arel.sql("ts_rank_cd(#{text_expression}, plainto_tsquery('english', #{quoted_query})) DESC"))
      .limit(DEFAULT_BM25_LIMIT)
      .to_a
  end

  def rank_results(vector_results, bm25_results, limit)
    score_by_id = Hash.new(0.0)

    vector_results.each_with_index do |chunk, index|
      score_by_id[chunk.id] += 1.0 / (RRF_K + index + 1)
    end

    bm25_results.each_with_index do |chunk, index|
      score_by_id[chunk.id] += 1.0 / (RRF_K + index + 1)
    end

    records_by_id = (vector_results + bm25_results).index_by(&:id)
    score_by_id
      .sort_by { |(_id, score)| -score }
      .first(limit)
      .filter_map { |(id, _score)| records_by_id[id] }
  end
end
