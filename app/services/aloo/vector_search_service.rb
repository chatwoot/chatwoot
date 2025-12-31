# frozen_string_literal: true

module Aloo
  class VectorSearchService
    include Aloo::ContextBudget

    DEFAULT_LIMIT = 10
    SIMILARITY_THRESHOLD = 0.3 # Minimum similarity score to include

    def initialize(assistant:, account:)
      @assistant = assistant
      @account = account
      validate_params!
    end

    # Search knowledge base for relevant content
    # @param query [String] The search query
    # @param limit [Integer] Maximum number of results
    # @param source_types [Array<String>] Filter by source types (file, webpage, etc.)
    # @return [Array<Hash>] Ranked search results with scores
    def search(query, limit: DEFAULT_LIMIT, source_types: nil)
      return [] if query.blank?

      query_embedding = generate_query_embedding(query)
      return [] unless query_embedding

      Aloo::Trace.record_with_timing(
        trace_type: 'search',
        account: @account,
        assistant: @assistant,
        input_data: { query: query, limit: limit, source_types: source_types }
      ) do
        results = fetch_similar_embeddings(query_embedding, limit * 2, source_types)
        ranked_results = rank_results(results, query)
        format_results(ranked_results.first(limit))
      end
    end

    # Search and return formatted context for LLM
    # @param query [String] The search query
    # @param max_tokens [Integer] Maximum tokens for context
    # @return [String] Formatted context string
    def search_for_context(query, max_tokens: KNOWLEDGE_CONTEXT_TOKENS)
      results = search(query, limit: 20)
      build_context_string(results, max_tokens)
    end

    # Find similar documents to a given embedding
    # @param embedding [Array<Float>] The embedding vector
    # @param limit [Integer] Maximum number of results
    # @return [Array<Aloo::Embedding>] Similar embeddings
    def find_similar(embedding, limit: DEFAULT_LIMIT)
      Aloo::Embedding
        .joins(:document)
        .where(aloo_documents: { aloo_assistant_id: @assistant.id })
        .where(account: @account)
        .nearest_neighbors(:embedding, embedding, distance: 'cosine')
        .limit(limit)
    end

    private

    def validate_params!
      raise ArgumentError, 'Account required' unless @account
      raise ArgumentError, 'Assistant required' unless @assistant
      raise ArgumentError, 'Account mismatch' unless @assistant.account_id == @account.id
    end

    def generate_query_embedding(query)
      embedding_service = Aloo::EmbeddingService.new(account: @account)
      embedding_service.generate_embedding(query)
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::VectorSearchService] Query embedding failed: #{e.message}")
      nil
    end

    def fetch_similar_embeddings(query_embedding, limit, source_types)
      scope = Aloo::Embedding
              .joins(:document)
              .where(aloo_documents: { aloo_assistant_id: @assistant.id })
              .where(account: @account)
              .where(aloo_documents: { status: 'processed' })

      if source_types.present?
        scope = scope.where(aloo_documents: { source_type: source_types })
      end

      scope
        .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
        .limit(limit)
        .includes(:document)
    end

    def rank_results(embeddings, query)
      embeddings.map do |embedding|
        # neighbor_distance is cosine distance (0 = identical, 2 = opposite)
        # Convert to similarity score (1 = identical, 0 = orthogonal)
        similarity = 1.0 - (embedding.neighbor_distance / 2.0)

        # Skip results below threshold
        next nil if similarity < SIMILARITY_THRESHOLD

        # Calculate final score with boosts
        score = calculate_score(embedding, similarity)

        {
          embedding: embedding,
          document: embedding.document,
          content: embedding.content,
          similarity: similarity,
          score: score
        }
      end.compact.sort_by { |r| -r[:score] }
    end

    def calculate_score(embedding, similarity)
      weights = Aloo::RankingConfig::WEIGHTS

      # Base similarity score
      score = similarity * weights[:similarity]

      # Recency boost (documents updated recently get a small boost)
      recency_score = calculate_recency_score(embedding.document)
      score += recency_score * weights[:recency]

      # Source type boost (certain sources may be more authoritative)
      score += source_type_boost(embedding.document)

      score.clamp(0.0, 1.0)
    end

    def calculate_recency_score(document)
      return 0.5 unless document.updated_at

      days_old = (Time.current - document.updated_at) / 1.day
      # Decay over 90 days
      [1.0 - (days_old / 90.0), 0.0].max
    end

    def source_type_boost(document)
      # Files get a small boost as they're typically more curated
      document.source_type == 'file' ? 0.05 : 0.0
    end

    def format_results(ranked_results)
      ranked_results.map do |result|
        {
          id: result[:embedding].id,
          document_id: result[:document].id,
          document_title: result[:document].title,
          content: result[:content],
          source_type: result[:document].source_type,
          similarity: result[:similarity].round(4),
          score: result[:score].round(4),
          metadata: result[:document].metadata
        }
      end
    end

    def build_context_string(results, max_tokens)
      return '' if results.empty?

      context_parts = []
      current_tokens = 0

      results.each do |result|
        content = result[:content]
        estimated_tokens = (content.length / Aloo::ContextBudget::CHARS_PER_TOKEN.to_f).ceil

        break if current_tokens + estimated_tokens > max_tokens

        context_parts << format_context_entry(result)
        current_tokens += estimated_tokens
      end

      context_parts.join("\n\n---\n\n")
    end

    def format_context_entry(result)
      header = "[Source: #{result[:document_title]}]"
      "#{header}\n#{result[:content]}"
    end
  end
end
