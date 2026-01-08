# frozen_string_literal: true

module Aloo
  class Document < ApplicationRecord
    self.table_name = 'aloo_documents'

    include Aloo::AccountScoped

    belongs_to :assistant, class_name: 'Aloo::Assistant', foreign_key: 'aloo_assistant_id', inverse_of: :documents
    has_many :embeddings, class_name: 'Aloo::Embedding', foreign_key: 'aloo_document_id', dependent: :destroy, inverse_of: :document

    has_one_attached :file

    # Document processing status
    enum :status, {
      pending: 0,
      processing: 1,
      available: 2,
      failed: 3,
      unsupported: 4
    }, default: :pending

    # V1: Only file source type supported
    # V2: website, notion
    validates :source_type, inclusion: { in: Aloo::SUPPORTED_SOURCE_TYPES }
    validates :title, presence: true, if: :available?

    scope :available, -> { where(status: :available) }
    scope :by_source_type, ->(type) { where(source_type: type) }

    # Queue document for processing
    def process_async!
      update!(status: :processing)
      Aloo::ProcessDocumentJob.perform_later(id)
    end

    # Mark as failed with error
    def mark_failed!(message)
      update!(status: :failed, error_message: message)
    end

    # Mark as available after successful processing
    def mark_available!
      update!(status: :available, error_message: nil)
    end

    # Check if document has embeddings
    def embedded?
      embeddings.exists?
    end

    # Get chunk count
    def chunk_count
      embeddings.count
    end

    # Process document synchronously (blocking)
    def process_sync!
      Aloo::ProcessDocumentJob.new.perform(id)
    end

    # Clear and re-process from scratch
    def reprocess!
      embeddings.destroy_all
      update!(status: :pending, error_message: nil)
      process_async!
    end
  end
end
