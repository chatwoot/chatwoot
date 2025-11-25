module ProductCatalogs
  class ProcessFullExportJob < ApplicationJob
    queue_as :high

    def perform(bulk_request_id)
      bulk_request = BulkProcessingRequest.find(bulk_request_id)

      # Check if job was cancelled before starting
      return if bulk_request.cancelled?

      begin
        # Update status to processing
        bulk_request.update!(
          status: 'PROCESSING',
          job_id: provider_job_id
        )

        # Get all products for the account
        products = bulk_request.account.product_catalogs.order(:id)
        total_count = products.count

        # Update total records
        bulk_request.update!(total_records: total_count)

        # Generate Excel file using the exporter service with progress updates
        excel_data = ProductCatalogs::ExcelExporterService.new(products, total_count: total_count).export do |processed, total|
          # Check if cancelled during processing
          bulk_request.reload
          raise 'Export cancelled by user' if bulk_request.cancelled?

          # Update progress
          progress = (processed.to_f / total * 100).round(2)
          bulk_request.update!(
            processed_records: processed,
            progress: progress
          )

          Rails.logger.info "Export progress: #{processed}/#{total} (#{progress}%)"
        end

        # Create a temporary file
        temp_file = Tempfile.new(['product_export', '.xlsx'])
        temp_file.binmode
        temp_file.write(excel_data)
        temp_file.rewind

        # Generate filename for the export
        export_filename = "product_catalog_full_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx"

        # Attach the file to the bulk request
        bulk_request.export_file.attach(
          io: temp_file,
          filename: export_filename,
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )

        # Close and delete the temporary file
        temp_file.close
        temp_file.unlink

        # Mark as completed with the file name
        bulk_request.update!(
          status: 'COMPLETED',
          processed_records: total_count,
          progress: 100.0,
          file_name: export_filename,
          dismissed_at: nil # Ensure it's not dismissed so user can see it
        )

        # Send email notification to user
        ProductCatalogMailer.export_completed(bulk_request).deliver_later

        # Schedule cleanup job for 24 hours from now
        ProductCatalogs::CleanupExportFileJob.set(wait: 24.hours).perform_later(bulk_request_id)

      rescue StandardError => e
        Rails.logger.error "Full export failed for bulk_request_id=#{bulk_request_id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        bulk_request.update!(
          status: 'FAILED',
          error_message: e.message
        )

        raise e
      end
    end
  end
end
