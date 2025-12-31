# frozen_string_literal: true

module Aloo
  class Memory < ApplicationRecord
    self.table_name = 'aloo_memories'

    include Aloo::AccountScoped # CRITICAL: Always scope by account
    include Aloo::Embeddable

    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               inverse_of: :memories
    belongs_to :contact, optional: true
    belongs_to :conversation, optional: true
    has_many :message_feedbacks,
             class_name: 'Aloo::MessageFeedback',
             foreign_key: 'aloo_memory_id',
             dependent: :destroy,
             inverse_of: :memory

    MEMORY_TYPES = %w[correction decision preference insight commitment gap faq procedure].freeze

    validates :memory_type, inclusion: { in: MEMORY_TYPES }
    validates :content, presence: true

    # Standard scopes
    scope :active, -> { where('confidence > ?', 0.2) }
    scope :by_type, ->(type) { where(memory_type: type) }
    scope :for_contact, ->(contact_id) { where(contact_id: contact_id) }
    scope :with_entity, ->(entity) { where('? = ANY(entities)', entity) }
    scope :with_topic, ->(topic) { where('? = ANY(topics)', topic) }

    # Memory type scoping - contact-scoped vs global
    # Contact-scoped: about THIS customer (preference, commitment, decision, correction)
    # Global: apply to all conversations (procedure, faq, insight, gap)
    scope :contact_scoped, -> { where(memory_type: Aloo::CONTACT_SCOPED_TYPES) }
    scope :global_scoped, -> { where(memory_type: Aloo::GLOBAL_TYPES) }

    # For Embeddable concern
    def embedding_content
      source_excerpt.presence || content
    end

    def contact_scoped?
      Aloo::CONTACT_SCOPED_TYPES.include?(memory_type)
    end

    def global_scoped?
      Aloo::GLOBAL_TYPES.include?(memory_type)
    end

    def record_observation!
      update!(
        observation_count: observation_count + 1,
        last_observed_at: Time.current,
        confidence: [confidence + 0.05, 1.0].min
      )
    end

    def record_feedback!(helpful:)
      if helpful
        update!(
          helpful_count: helpful_count + 1,
          confidence: [confidence + 0.1, 1.0].min
        )
      else
        new_confidence = [confidence - 0.15, 0.0].max
        update!(
          not_helpful_count: not_helpful_count + 1,
          confidence: new_confidence,
          flagged_for_review: not_helpful_count >= 3
        )
      end
    end

    # Calculate ranking score with multiple signals
    # Uses centralized weights from RankingConfig
    def ranking_score(query_similarity:, query_type_boost: nil)
      RankingConfig.calculate_score(
        similarity: query_similarity,
        confidence: confidence,
        observation_count: observation_count,
        last_observed_at: last_observed_at,
        query_type_boost: query_type_boost,
        memory_type: memory_type
      )
    end

    # Build display format for context
    def to_context_format
      scope_label = contact_scoped? ? '[Personal]' : '[General]'
      type_label = memory_type.titleize
      "#{scope_label} [#{type_label}] #{content}"
    end
  end
end
