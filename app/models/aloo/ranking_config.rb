# frozen_string_literal: true

module Aloo
  module RankingConfig
    # Multi-signal ranking weights (must sum to ~1.0 before boost)
    WEIGHTS = {
      similarity: 0.60,    # Vector cosine similarity
      confidence: 0.15,    # How reliable is this memory
      observation: 0.10,   # Times confirmed across sessions
      recency: 0.10        # Exponential decay from last use
    }.freeze

    # Query-type boost when intent matches memory type
    TYPE_BOOST = 0.15

    # Similarity thresholds
    ENTITY_THRESHOLD = 0.40    # Lower when entities match
    SEMANTIC_THRESHOLD = 0.50  # Higher for pure semantic search

    # Recency decay
    RECENCY_HALF_LIFE_DAYS = 30

    # Type boost keywords - detect query intent
    TYPE_BOOST_KEYWORDS = {
      'correction' => %w[mistake wrong error incorrect fix],
      'decision' => %w[decided chose agreed decision choice],
      'preference' => %w[prefer like want preference favorite],
      'commitment' => %w[promised committed will guarantee follow-up],
      'gap' => %w[don't know couldn't answer missing unclear],
      'insight' => %w[learned discovered found realized],
      'faq' => %w[how what why when where question],
      'procedure' => %w[process steps workflow procedure how-to]
    }.freeze

    class << self
      # Detect which memory type should be boosted based on query
      def detect_type_boost(query)
        query_lower = query.to_s.downcase

        TYPE_BOOST_KEYWORDS.each do |type, keywords|
          return type if keywords.any? { |kw| query_lower.include?(kw) }
        end

        nil
      end

      # Calculate recency score with exponential decay
      def recency_score(last_observed_at)
        return 1.0 unless last_observed_at

        days_ago = (Time.current - last_observed_at) / 1.day
        decay_rate = Math.log(2) / RECENCY_HALF_LIFE_DAYS
        Math.exp(-decay_rate * days_ago)
      end

      # Calculate observation score (log scale, max at ~100 observations)
      def observation_score(count)
        [Math.log10(count.to_i + 1) / 2.0, 1.0].min
      end

      # Calculate combined ranking score
      def calculate_score(similarity:, confidence:, observation_count:, last_observed_at:, query_type_boost: nil, memory_type: nil)
        signals = {
          similarity: similarity * WEIGHTS[:similarity],
          confidence: confidence * WEIGHTS[:confidence],
          observation: observation_score(observation_count) * WEIGHTS[:observation],
          recency: recency_score(last_observed_at) * WEIGHTS[:recency]
        }

        base_score = signals.values.sum

        # Apply type boost if query intent matches memory type
        if query_type_boost.present? && query_type_boost == memory_type
          base_score * (1 + TYPE_BOOST)
        else
          base_score
        end
      end
    end
  end
end
