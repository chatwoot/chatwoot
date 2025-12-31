# frozen_string_literal: true

module Aloo
  class MessageFeedback < ApplicationRecord
    self.table_name = 'aloo_message_feedbacks'

    belongs_to :message
    belongs_to :memory,
               class_name: 'Aloo::Memory',
               foreign_key: 'aloo_memory_id',
               optional: true,
               inverse_of: :message_feedbacks
    belongs_to :user, optional: true

    FEEDBACK_TYPES = %w[helpful not_helpful].freeze

    validates :feedback_type, inclusion: { in: FEEDBACK_TYPES }

    scope :helpful, -> { where(feedback_type: 'helpful') }
    scope :not_helpful, -> { where(feedback_type: 'not_helpful') }
    scope :recent, -> { where('created_at > ?', 7.days.ago) }

    after_create :update_memory_confidence

    def helpful?
      feedback_type == 'helpful'
    end

    def not_helpful?
      feedback_type == 'not_helpful'
    end

    private

    def update_memory_confidence
      return unless memory

      memory.record_feedback!(helpful: helpful?)
    end
  end
end
