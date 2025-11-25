module ProductCatalogs
  class CleanupExportFileJob < ApplicationJob
    queue_as :low

    def perform(bulk_request_id)
      bulk_request = BulkProcessingRequest.find_by(id: bulk_request_id)
      return unless bulk_request

      # Only cleanup if it's an export operation and it's completed
      return unless bulk_request.operation_export? && bulk_request.completed?

      # Remove the attached export file
      bulk_request.export_file.purge if bulk_request.export_file.attached?

      Rails.logger.info "Cleaned up export file for bulk_request_id=#{bulk_request_id}"
    end
  end
end
