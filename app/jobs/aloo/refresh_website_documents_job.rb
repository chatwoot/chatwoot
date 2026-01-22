# frozen_string_literal: true

module Aloo
  class RefreshWebsiteDocumentsJob < ApplicationJob
    queue_as :low

    # Find all website documents due for refresh and reprocess them
    def perform
      documents = Aloo::Document.due_for_refresh

      Rails.logger.info("[Aloo::RefreshWebsiteDocumentsJob] Found #{documents.count} documents due for refresh")

      documents.find_each do |document|
        refresh_document(document)
      rescue StandardError => e
        Rails.logger.error("[Aloo::RefreshWebsiteDocumentsJob] Failed to refresh document #{document.id}: #{e.message}")
      end
    end

    private

    def refresh_document(document)
      Rails.logger.info("[Aloo::RefreshWebsiteDocumentsJob] Refreshing document #{document.id}: #{document.title}")

      # Clear existing embeddings
      document.embeddings.destroy_all

      # Reset status and queue for processing
      document.update!(
        status: :pending,
        error_message: nil,
        metadata: document.metadata.merge('refresh_triggered_at' => Time.current.iso8601)
      )

      # Queue the document for processing
      Aloo::ProcessDocumentJob.perform_later(document.id)

      # Schedule the next refresh
      document.schedule_next_refresh!
    end
  end
end
