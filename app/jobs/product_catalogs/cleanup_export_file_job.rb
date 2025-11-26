module ProductCatalogs
  class CleanupExportFileJob < ApplicationJob
    queue_as :low

    def perform(bulk_request_id)
      bulk_request = BulkProcessingRequest.find_by(id: bulk_request_id)
      return unless bulk_request

      # Only cleanup if it's an export operation and it's completed
      return unless bulk_request.operation_export? && bulk_request.completed?

      # Remove the attached export files (new multiple files format)
      if bulk_request.export_files.attached?
        count = bulk_request.export_files.count
        bulk_request.export_files.purge
        Rails.logger.info "Cleaned up #{count} export files for bulk_request_id=#{bulk_request_id}"
      end

      # Remove legacy single export file
      if bulk_request.export_file.attached?
        bulk_request.export_file.purge
        Rails.logger.info "Cleaned up legacy export file for bulk_request_id=#{bulk_request_id}"
      end
    end
  end
end
