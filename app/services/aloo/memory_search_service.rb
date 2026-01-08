# frozen_string_literal: true

module Aloo
  class MemorySearchService
    include Aloo::ContextBudget

    DEFAULT_LIMIT = 10
    SIMILARITY_THRESHOLD = 0.35
    DUPLICATE_THRESHOLD = 0.15 # For detecting near-duplicate memories

    def initialize(assistant:, account:)
      @assistant = assistant
      @account = account
      validate_params!
    end

    # Hybrid search combining contact-scoped and global memories
    # @param query [String] The search query
    # @param contact [Contact, nil] The contact for scoped memories
    # @param limit [Integer] Maximum number of results
    # @return [Array<Hash>] Ranked memory results with scores
    def search(query, contact: nil, limit: DEFAULT_LIMIT)
      return [] if query.blank?

      query_embedding = generate_query_embedding(query)
      return [] unless query_embedding

      Aloo::Trace.record_with_timing(
        trace_type: 'search',
        account: @account,
        assistant: @assistant,
        input_data: { query: query, contact_id: contact&.id, search_type: 'memory' }
      ) do
        # Split limit between contact-scoped and global
        contact_limit = contact ? (limit / 2.0).ceil : 0
        global_limit = contact ? (limit / 2.0).floor : limit

        contact_results = contact ? search_contact_scoped(query_embedding, contact, contact_limit) : []
        global_results = search_global(query_embedding, global_limit)

        merge_and_rank(contact_results, global_results, limit)
      end
    end

    # Search and return formatted context for LLM
    # @param query [String] The search query
    # @param contact [Contact, nil] The contact for scoped memories
    # @param max_tokens [Integer] Maximum tokens for context
    # @return [String] Formatted context string
    def search_for_context(query, contact: nil, max_tokens: MEMORY_CONTEXT_TOKENS)
      results = search(query, contact: contact, limit: 15)
      build_context_string(results, max_tokens)
    end

    # Find memories by specific type
    # @param memory_type [String] The memory type to find
    # @param contact [Contact, nil] The contact for scoped memories
    # @param limit [Integer] Maximum number of results
    # @return [Array<Aloo::Memory>] Matching memories
    def find_by_type(memory_type, contact: nil, limit: DEFAULT_LIMIT)
      scope = base_scope.where(memory_type: memory_type)
      scope = scope.for_contact(contact) if contact && Aloo::CONTACT_SCOPED_TYPES.include?(memory_type)
      scope.active.order(confidence: :desc).limit(limit)
    end

    # Check if a similar memory already exists (for deduplication)
    # @param content [String] The memory content to check
    # @param memory_type [String] The memory type
    # @param contact [Contact, nil] The contact for scoped memories
    # @return [Aloo::Memory, nil] Existing similar memory or nil
    def find_duplicate(content, memory_type, contact: nil)
      return nil if content.blank?

      query_embedding = generate_query_embedding(content)
      return nil unless query_embedding

      scope = base_scope.where(memory_type: memory_type).active

      scope = scope.for_contact(contact) if contact && Aloo::CONTACT_SCOPED_TYPES.include?(memory_type)

      candidates = scope
                   .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
                   .limit(5)

      candidates.find do |memory|
        similarity = 1.0 - (memory.neighbor_distance / 2.0)
        similarity > (1.0 - DUPLICATE_THRESHOLD)
      end
    end

    private

    def validate_params!
      raise ArgumentError, 'Account required' unless @account
      raise ArgumentError, 'Assistant required' unless @assistant
      raise ArgumentError, 'Account mismatch' unless @assistant.account_id == @account.id
    end

    def base_scope
      @assistant.memories.where(account: @account)
    end

    def generate_query_embedding(query)
      embedding_service = Aloo::EmbeddingService.new(account: @account)
      embedding_service.generate_embedding(query)
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::MemorySearchService] Query embedding failed: #{e.message}")
      nil
    end

    def search_contact_scoped(query_embedding, contact, limit)
      return [] if limit <= 0

      memories = base_scope
                 .contact_scoped
                 .for_contact(contact)
                 .active
                 .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
                 .limit(limit * 2)

      rank_memories(memories).first(limit)
    end

    def search_global(query_embedding, limit)
      return [] if limit <= 0

      memories = base_scope
                 .global_scoped
                 .active
                 .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
                 .limit(limit * 2)

      rank_memories(memories).first(limit)
    end

    def rank_memories(memories)
      memories.map do |memory|
        similarity = 1.0 - (memory.neighbor_distance / 2.0)
        next nil if similarity < SIMILARITY_THRESHOLD

        score = calculate_score(memory, similarity)

        {
          memory: memory,
          similarity: similarity,
          score: score
        }
      end.compact.sort_by { |r| -r[:score] }
    end

    def calculate_score(memory, similarity)
      weights = Aloo::RankingConfig::WEIGHTS

      # Base similarity score (normalized to 0-1)
      score = similarity * weights[:similarity]

      # Confidence score (already 0-1)
      score += (memory.confidence || 0.5) * weights[:confidence]

      # Observation count boost (normalized, caps at 10 observations)
      observation_score = [(memory.observation_count || 1) / 10.0, 1.0].min
      score += observation_score * weights[:observation]

      # Recency boost
      recency_score = calculate_recency_score(memory)
      score += recency_score * weights[:recency]

      # Type boost for high-priority types
      score += type_boost(memory.memory_type)

      score.clamp(0.0, 1.0)
    end

    def calculate_recency_score(memory)
      return 0.5 unless memory.last_observed_at

      days_old = (Time.current - memory.last_observed_at) / 1.day
      # Decay over 30 days for memories (faster than documents)
      [1.0 - (days_old / 30.0), 0.0].max
    end

    def type_boost(memory_type)
      # Preferences and commitments get priority
      Aloo::RankingConfig.type_boost_for?(memory_type) ? Aloo::RankingConfig::TYPE_BOOST : 0.0
    end

    def merge_and_rank(contact_results, global_results, limit)
      all_results = contact_results + global_results

      # Re-sort by final score
      ranked = all_results.sort_by { |r| -r[:score] }

      format_results(ranked.first(limit))
    end

    def format_results(ranked_results)
      ranked_results.map do |result|
        memory = result[:memory]
        {
          id: memory.id,
          memory_type: memory.memory_type,
          content: memory.content,
          entities: memory.entities,
          topics: memory.topics,
          confidence: memory.confidence,
          observation_count: memory.observation_count,
          is_contact_scoped: Aloo::CONTACT_SCOPED_TYPES.include?(memory.memory_type),
          similarity: result[:similarity].round(4),
          score: result[:score].round(4),
          source_conversation_id: memory.metadata&.dig('source_conversation_id')
        }
      end
    end

    def build_context_string(results, max_tokens)
      return '' if results.empty?

      context_parts = []
      current_tokens = 0

      results.each do |result|
        entry = format_context_entry(result)
        estimated_tokens = (entry.length / Aloo::ContextBudget::CHARS_PER_TOKEN.to_f).ceil

        break if current_tokens + estimated_tokens > max_tokens

        context_parts << entry
        current_tokens += estimated_tokens
      end

      context_parts.join("\n")
    end

    def format_context_entry(result)
      type_label = result[:memory_type].humanize
      scope_label = result[:is_contact_scoped] ? 'Customer-specific' : 'General'

      "[#{type_label} - #{scope_label}] #{result[:content]}"
    end
  end
end
