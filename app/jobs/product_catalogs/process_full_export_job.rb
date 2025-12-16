module ProductCatalogs
  class ProcessFullExportJob < ApplicationJob
    queue_as :high

    # IMPORTANT: Disable retries - if export fails, do NOT retry
    discard_on StandardError do |job, error|
      bulk_request = BulkProcessingRequest.find_by(id: job.arguments.first)
      if bulk_request
        Rails.logger.error "=" * 60
        Rails.logger.error "[ExportJob] EXPORT FAILED"
        Rails.logger.error "[ExportJob] Bulk Request ID: #{bulk_request.id}"
        Rails.logger.error "[ExportJob] Error: #{error.message}"
        Rails.logger.error "[ExportJob] Backtrace:\n#{error.backtrace.first(10).join("\n")}"
        Rails.logger.error "=" * 60

        bulk_request.update!(
          status: 'FAILED',
          error_message: error.message
        )
      end
    end

    def perform(bulk_request_id)
      bulk_request = BulkProcessingRequest.find(bulk_request_id)

      Rails.logger.info "=" * 60
      Rails.logger.info "[ExportJob] JOB STARTED"
      Rails.logger.info "[ExportJob] Bulk Request ID: #{bulk_request_id}"
      Rails.logger.info "[ExportJob] Account ID: #{bulk_request.account_id}"
      Rails.logger.info "[ExportJob] User ID: #{bulk_request.user_id}"
      Rails.logger.info "=" * 60

      # Check if job was cancelled before starting
      if bulk_request.cancelled?
        Rails.logger.info "[ExportJob] Job was cancelled before starting. Exiting."
        return
      end

      # Update status to processing
      bulk_request.update!(
        status: 'PROCESSING',
        job_id: provider_job_id
      )
      Rails.logger.info "[ExportJob] Status updated to PROCESSING"

      # Get all products for the account
      Rails.logger.info "[ExportJob] Counting products..."
      products = bulk_request.account.product_catalogs.order(:id)
      total_count = products.count

      Rails.logger.info "[ExportJob] Total products to export: #{total_count}"

      # Update total records
      bulk_request.update!(total_records: total_count)

      # Generate Excel files using the exporter service (multiple files if > 50k products)
      exporter = ProductCatalogs::ExcelExporterService.new(products, total_count: total_count)
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      file_count = 0
      attached_files = []

      Rails.logger.info "[ExportJob] Starting export with ExcelExporterService..."

      # Progress callback - updates database every 2000 products
      progress_callback = lambda do |processed, total, percent, status_message|
        # Check if cancelled
        bulk_request.reload
        if bulk_request.cancelled?
          Rails.logger.info "[ExportJob] Export cancelled during progress update"
          raise 'Export cancelled by user'
        end

        # Update database with current progress
        bulk_request.update!(
          processed_records: processed,
          progress: percent,
          error_message: status_message # Use error_message temporarily to store status
        )

        Rails.logger.info "[ExportJob] Progress updated: #{percent}% - #{status_message}"
      end

      exporter.export_in_chunks(on_progress: progress_callback) do |excel_data, file_number, processed_so_far, progress_info|
        # Check if cancelled during processing
        bulk_request.reload
        if bulk_request.cancelled?
          Rails.logger.info "[ExportJob] Export cancelled by user during processing"
          raise 'Export cancelled by user'
        end

        Rails.logger.info "[ExportJob] Received file #{file_number} from exporter"
        Rails.logger.info "[ExportJob]   Size: #{progress_info[:file_size_kb]} KB"
        Rails.logger.info "[ExportJob]   Products: #{progress_info[:products_in_file]}"

        # Create a temporary file
        temp_file = Tempfile.new(['product_export', '.xlsx'])
        temp_file.binmode
        temp_file.write(excel_data)
        temp_file.rewind

        # Generate filename for this part
        export_filename = if total_count > ProductCatalogs::ExcelExporterService::MAX_PRODUCTS_PER_FILE
                            "product_catalog_export_#{timestamp}_part#{file_number}.xlsx"
                          else
                            "product_catalog_full_export_#{timestamp}.xlsx"
                          end

        Rails.logger.info "[ExportJob] Attaching file: #{export_filename}"

        # Attach the file to the bulk request (using has_many_attached :export_files)
        bulk_request.export_files.attach(
          io: temp_file,
          filename: export_filename,
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )

        attached_files << export_filename
        Rails.logger.info "[ExportJob] File attached successfully"

        # Close and delete the temporary file
        temp_file.close
        temp_file.unlink

        file_count = file_number

        # Update progress in database
        progress = (processed_so_far.to_f / total_count * 100).round(2)
        bulk_request.update!(
          processed_records: processed_so_far,
          progress: progress
        )

        Rails.logger.info "[ExportJob] Database updated: #{processed_so_far}/#{total_count} (#{progress}%)"
      end

      # Generate display filename
      display_filename = if file_count > 1
                           "product_catalog_export_#{timestamp} (#{file_count} files).zip"
                         else
                           attached_files.first || "product_catalog_full_export_#{timestamp}.xlsx"
                         end

      Rails.logger.info "[ExportJob] Export completed successfully!"
      Rails.logger.info "[ExportJob] Total files: #{file_count}"
      Rails.logger.info "[ExportJob] Display filename: #{display_filename}"

      # Mark as completed - clear error_message since it was used for status updates
      bulk_request.update!(
        status: 'COMPLETED',
        processed_records: total_count,
        progress: 100.0,
        file_name: display_filename,
        error_message: nil, # Clear status message
        dismissed_at: nil # Ensure it's not dismissed so user can see it
      )

      Rails.logger.info "[ExportJob] Status updated to COMPLETED"

      # Send email notification to user
      ProductCatalogMailer.export_completed(bulk_request).deliver_later
      Rails.logger.info "[ExportJob] Email notification queued"

      # Schedule cleanup job for 24 hours from now
      ProductCatalogs::CleanupExportFileJob.set(wait: 24.hours).perform_later(bulk_request_id)
      Rails.logger.info "[ExportJob] Cleanup job scheduled for 24 hours from now"

      Rails.logger.info "=" * 60
      Rails.logger.info "[ExportJob] JOB COMPLETED SUCCESSFULLY"
      Rails.logger.info "=" * 60
    end
  end
end
