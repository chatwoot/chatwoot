# frozen_string_literal: true

module Aloo
  class Embedding < ApplicationRecord
    self.table_name = 'aloo_embeddings'

    include Aloo::AccountScoped
    include Aloo::Embeddable

    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               inverse_of: :embeddings
    belongs_to :document,
               class_name: 'Aloo::Document',
               foreign_key: 'aloo_document_id',
               optional: true,
               inverse_of: :embeddings

    # Embedding approval status
    enum :status, {
      pending: 0,
      approved: 1,
      rejected: 2
    }, default: :pending

    validates :content, presence: true

    scope :approved, -> { where(status: :approved) }
    scope :for_search, -> { approved.with_embedding }
    scope :with_question, -> { where.not(question: nil) }

    # For Embeddable concern - content to embed
    def embedding_content
      # If Q&A format, combine question and answer
      if question.present?
        "Q: #{question}\nA: #{content}"
      else
        content
      end
    end

    # Build display format for context
    def to_context_format
      if question.present?
        "Q: #{question}\nA: #{content}"
      else
        content
      end
    end

    # Get source info
    def source_info
      {
        document_title: document&.title,
        document_url: document&.source_url,
        chunk_index: metadata['chunk_index']
      }
    end
  end
end
