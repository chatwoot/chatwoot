class Captain::Documents::HybridChunkSearchService
  DEFAULT_VECTOR_LIMIT = 10
  DEFAULT_BM25_LIMIT = 10
  DEFAULT_BM25_CANDIDATE_LIMIT = 200
  DEFAULT_RESULT_LIMIT = 5
  RRF_K = 60
  BM25_K1 = 1.2
  BM25_B = 0.75
  ENGLISH_STOPWORDS = Set.new(
    %w[
      a an and are as at be by for from has have how i in is it of on or that the this to was what when
      where who why with your our their they we you do does did can could should would may might will
      about above after again against all am any because before being below between both but down during
      each few further here into more most other over own same some such than then there these those
      through under until up very while
    ]
  ).freeze

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
    query_terms = bm25_terms(query).uniq
    return [] if query_terms.blank?

    candidates = bm25_candidates(query_terms)
    return [] if candidates.blank?

    score_bm25_candidates(candidates, query_terms)
      .first(DEFAULT_BM25_LIMIT)
      .map(&:first)
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

  def bm25_candidates(query_terms)
    tsquery = build_or_tsquery(query_terms)
    return [] if tsquery.blank?

    quoted_tsquery = ActiveRecord::Base.connection.quote(tsquery)
    vector_expression = "to_tsvector('english', coalesce(captain_document_chunks.context, '') || ' ' || captain_document_chunks.content)"

    base_scope
      .where(Arel.sql("#{vector_expression} @@ to_tsquery('english', #{quoted_tsquery})"))
      .limit(DEFAULT_BM25_CANDIDATE_LIMIT)
      .to_a
  end

  def score_bm25_candidates(chunks, query_terms)
    documents = chunks.filter_map { |chunk| bm25_document_payload(chunk, query_terms) }
    return [] if documents.blank?

    scoring_context = bm25_scoring_context(documents, query_terms)
    scores = documents.map do |document|
      [document[:chunk], bm25_document_score(document, scoring_context)]
    end
    scores.sort_by { |(_chunk, score)| -score }
  end

  def bm25_document_payload(chunk, query_terms)
    terms = bm25_terms([chunk.context, chunk.content].join(' '))
    return nil if terms.blank?

    term_frequencies = terms.tally.slice(*query_terms)
    return nil if term_frequencies.blank?

    {
      chunk: chunk,
      doc_length: terms.length,
      term_freqs: term_frequencies
    }
  end

  def bm25_document_frequency(documents, query_terms)
    query_terms.index_with do |term|
      documents.count { |document| document[:term_freqs].key?(term) }
    end
  end

  def average_document_length(documents)
    total_tokens = documents.sum { |document| document[:doc_length] }
    return 1.0 if total_tokens.zero?

    total_tokens.to_f / documents.size
  end

  def bm25_scoring_context(documents, query_terms)
    {
      avg_doc_length: average_document_length(documents),
      doc_frequency: bm25_document_frequency(documents, query_terms),
      total_documents: documents.size,
      query_terms: query_terms
    }
  end

  def bm25_document_score(document, scoring_context)
    term_frequencies = document[:term_freqs]
    scoring_context[:query_terms].sum do |term|
      bm25_term_score(term, term_frequencies[term].to_i, document[:doc_length], scoring_context)
    end
  end

  def bm25_term_score(term, term_frequency, doc_length, scoring_context)
    return 0.0 if term_frequency.zero?

    document_frequency = scoring_context[:doc_frequency][term].to_i
    return 0.0 if document_frequency.zero?

    idf = bm25_inverse_document_frequency(document_frequency, scoring_context[:total_documents])
    denominator = bm25_denominator(term_frequency, doc_length, scoring_context[:avg_doc_length])
    idf * ((term_frequency * (BM25_K1 + 1.0)) / denominator)
  end

  def bm25_inverse_document_frequency(document_frequency, total_documents)
    Math.log(1.0 + ((total_documents - document_frequency + 0.5) / (document_frequency + 0.5)))
  end

  def bm25_denominator(term_frequency, doc_length, avg_doc_length)
    term_frequency + (BM25_K1 * (1.0 - BM25_B + (BM25_B * doc_length / avg_doc_length)))
  end

  def bm25_terms(text)
    text
      .to_s
      .downcase
      .scan(/[a-z0-9]+/)
      .reject { |token| token.length < 2 || ENGLISH_STOPWORDS.include?(token) }
  end

  def build_or_tsquery(query_terms)
    query_terms
      .map { |term| sanitize_tsquery_term(term) }
      .reject(&:blank?)
      .map { |term| "#{term}:*" }
      .join(' | ')
  end

  def sanitize_tsquery_term(term)
    term.to_s.gsub(/[^a-z0-9]/, '')
  end
end
