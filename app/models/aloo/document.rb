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
    # V2: website, text
    validates :source_type, inclusion: { in: Aloo::SUPPORTED_SOURCE_TYPES }
    validates :title, presence: true, if: :available?
    validates :text_content, presence: true, if: -> { source_type == 'text' }
    validate :validate_selected_pages_for_website

    scope :available, -> { where(status: :available) }
    scope :by_source_type, ->(type) { where(source_type: type) }
    scope :due_for_refresh, -> { where(auto_refresh: true).where('next_refresh_at <= ?', Time.current) }
    scope :websites_with_auto_refresh, -> { where(source_type: 'website', auto_refresh: true) }

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

    # Schedule next refresh for weekly auto-refresh (Sunday 3 AM UTC)
    def schedule_next_refresh!
      return unless auto_refresh && source_type == 'website'

      # Calculate next Sunday 3 AM UTC
      next_sunday = Time.current.utc.beginning_of_week(:sunday) + 1.week + 3.hours
      update!(
        last_refreshed_at: Time.current,
        next_refresh_at: next_sunday
      )
    end

    # Enable auto-refresh and set initial schedule
    def enable_auto_refresh!
      update!(auto_refresh: true)
      schedule_next_refresh!
    end

    # Disable auto-refresh
    def disable_auto_refresh!
      update!(auto_refresh: false, next_refresh_at: nil)
    end

    private

    def validate_selected_pages_for_website
      return unless source_type == 'website'
      return if selected_pages.blank? # Allow blank for backward compatibility

      errors.add(:selected_pages, 'must be an array') unless selected_pages.is_a?(Array)
    end
  end
end
