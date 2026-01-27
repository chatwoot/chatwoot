class ProductCatalogs::ProcessBulkUploadJob < ApplicationJob
  include Events::Types

  queue_as :high
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  def perform(bulk_request_id, file_path)
    @bulk_request = BulkProcessingRequest.find(bulk_request_id)
    @account = @bulk_request.account
    @user = @bulk_request.user
    @file_path = file_path

    begin
      process_upload
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  def process_upload
    # Check if request is still in a valid state to process
    current_status = @bulk_request.status.upcase
    unless ['PENDING', 'PROCESSING'].include?(current_status)
      Rails.logger.info("Skipping processing for bulk request #{@bulk_request.id} - status is #{current_status}")
      # Cleanup temp file even if we're not processing
      cleanup_temp_file
      return
    end

    @bulk_request.update!(status: 'PROCESSING')

    # Capture existing product_ids before processing to track adds vs updates
    @existing_product_ids_before = @account.product_catalogs.pluck(:product_id).to_set

    # Phase 1: Process Excel file (0-50% progress)
    excel_result = process_excel(@file_path)

    unless excel_result[:success]
      # Capture detailed error message and error details from Excel processing
      error_msg = excel_result[:error].presence || 'Excel processing failed'
      error_details = excel_result[:errors] || []

      @bulk_request.update!(
        status: 'FAILED',
        error_message: error_msg,
        error_details: error_details
      )

      # Cleanup temp file on failure
      cleanup_temp_file
      return
    end

    # Phase 2: Create ProductMedia entries from URLs (50-100% progress)
    media_result = create_media_entries

    # Update final status
    update_final_status(excel_result, media_result)

    # Cleanup temp file
    cleanup_temp_file

    # Broadcast completion notification
    broadcast_completion_notification
  end

  def process_excel(file_path)
    ProductCatalogs::ExcelProcessorService.new(
      file_path: file_path,
      account: @account,
      user: @user,
      bulk_request: @bulk_request
    ).process
  end

  def create_media_entries
    products = @bulk_request.product_catalogs.includes(:product_media)
    total_products = products.count
    processed = 0
    @media_errors = []

    products.find_each do |product|
      # Check if bulk request status is still valid for processing
      @bulk_request.reload
      current_status = @bulk_request.status.upcase
      unless ['PENDING', 'PROCESSING'].include?(current_status)
        Rails.logger.warn("Stopping media processing - bulk request #{@bulk_request.id} status is #{current_status}")
        break
      end

      begin
        create_media_for_product(product)
      rescue StandardError => e
        # Track media creation errors with detailed information
        @media_errors << {
          product_id: product.product_id,
          product_name: product.productName,
          error: e.message,
          photo_urls: product.photo_urls.first(3).join(', '),  # First 3 photo URLs
          pdf_urls: product.pdf_urls.first(3).join(', '),      # First 3 PDF URLs
          video_urls: product.video_urls.first(3).join(', ')   # First 3 video URLs
        }
      end

      processed += 1

      # Update progress from 50% to 100% every 100 products (less frequent for better performance)
      # Also update updated_at to keep the job alive in cleanup checks
      if processed % 100 == 0
        progress = 50 + (processed.to_f / total_products * 50).round(2)
        @bulk_request.update!(
          progress: progress,
          updated_at: Time.current
        )
      end
    end

    # Save media errors to bulk request
    if @media_errors.any?
      existing_errors = @bulk_request.error_details || []
      @bulk_request.update!(error_details: existing_errors + @media_errors)
    end

    { success: @media_errors.empty?, error: @media_errors.any? ? "#{@media_errors.count} products had media errors" : nil }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def create_media_for_product(product)
    # Clear existing media to avoid duplicates on re-upload
    product.product_media.destroy_all

    display_order = 0

    # Create ProductMedia for photos
    Rails.logger.info "Processing #{product.photo_urls.length} photo URLs for product #{product.product_id}"
    product.photo_urls.each_with_index do |url, index|
      Rails.logger.info "Processing photo #{index + 1}/#{product.photo_urls.length}: #{url}"
      filename = extract_filename_from_url(url, 'photo', index)
      Rails.logger.info "Extracted filename: #{filename}"

      begin
        media = product.product_media.create!(
          file_type: :image,
          file_url: url,
          file_name: filename,
          is_primary: index.zero?, # First photo is primary
          display_order: display_order,
          user_id: @user.id,
          last_updated_by_id: @user.id
        )
        Rails.logger.info "Successfully created IMAGE media with ID=#{media.id}"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to create IMAGE media: #{e.message}"
        Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
        raise
      end

      display_order += 1
    end

    # Create ProductMedia for videos
    product.video_urls.each_with_index do |url, index|
      product.product_media.create!(
        file_type: :video,
        file_url: url,
        file_name: extract_filename_from_url(url, 'video', index),
        display_order: display_order,
        user_id: @user.id,
        last_updated_by_id: @user.id
      )
      display_order += 1
    end

    # Create ProductMedia for PDFs
    product.pdf_urls.each_with_index do |url, index|
      product.product_media.create!(
        file_type: :document,
        file_url: url,
        file_name: extract_filename_from_url(url, 'document', index),
        display_order: display_order,
        user_id: @user.id,
        last_updated_by_id: @user.id
      )
      display_order += 1
    end
  end

  def extract_filename_from_url(url, default_prefix, index)
    # Try to extract filename from URL
    require 'uri'
    require 'cgi'

    uri = URI.parse(url)
    path = uri.path
    filename = File.basename(path)

    # URL decode the filename (e.g., "Desktop%20-%203.jpg" -> "Desktop - 3.jpg")
    filename = CGI.unescape(filename) if filename.present?

    # Check if filename has a valid extension for the file type
    if filename.present? && has_valid_extension?(filename, default_prefix)
      filename
    else
      # Use default naming with appropriate extension
      "#{default_prefix}_#{index + 1}.#{default_extension_for_prefix(default_prefix)}"
    end
  rescue StandardError => e
    # If URL parsing fails, use default naming
    Rails.logger.warn("Failed to extract filename from URL: #{url} - #{e.message}")
    "#{default_prefix}_#{index + 1}.#{default_extension_for_prefix(default_prefix)}"
  end

  def has_valid_extension?(filename, prefix)
    return false unless filename.include?('.')

    extension = File.extname(filename).downcase

    valid_extensions = case prefix
                       when 'photo'
                         %w[.jpg .jpeg .png .gif .webp .svg]
                       when 'video'
                         %w[.mp4 .avi .mov .wmv .flv .webm]
                       when 'document'
                         %w[.pdf .doc .docx .xls .xlsx .txt]
                       else
                         []
                       end

    valid_extensions.include?(extension)
  end

  def default_extension_for_prefix(prefix)
    case prefix
    when 'photo'
      'jpg'
    when 'video'
      'mp4'
    when 'document'
      'pdf'
    else
      'bin'
    end
  end

  def update_final_status(excel_result, media_result)
    if excel_result[:success] && media_result[:success]
      handle_successful_processing
    else
      handle_failed_processing(excel_result, media_result)
    end
  end

  def handle_successful_processing
    added_product_ids, updated_product_ids = categorize_processed_products

    if @bulk_request.failed_records.zero? && @bulk_request.processed_records.positive?
      complete_bulk_request(added_product_ids, updated_product_ids)
    elsif @bulk_request.failed_records.positive? && @bulk_request.processed_records.positive?
      partially_complete_bulk_request(added_product_ids, updated_product_ids)
    else
      fail_bulk_request('No records were processed successfully')
    end
  end

  def categorize_processed_products
    processed_products = @bulk_request.product_catalogs.pluck(:product_id)
    added_product_ids = []
    updated_product_ids = []

    processed_products.each do |product_id|
      if @existing_product_ids_before&.include?(product_id)
        updated_product_ids << product_id
      else
        added_product_ids << product_id
      end
    end

    [added_product_ids, updated_product_ids]
  end

  def complete_bulk_request(added_product_ids, updated_product_ids)
    @bulk_request.update!(status: 'COMPLETED', progress: 100.0, error_message: nil)
    dispatch_catalog_updated_event(
      added_count: added_product_ids.size,
      updated_count: updated_product_ids.size,
      deleted_count: 0,
      added_product_ids: added_product_ids,
      updated_product_ids: updated_product_ids,
      deleted_product_ids: []
    )
  end

  def partially_complete_bulk_request(added_product_ids, updated_product_ids)
    @bulk_request.update!(
      status: 'PARTIALLY_COMPLETED',
      progress: 100.0,
      error_message: "Processed #{@bulk_request.processed_records} of #{@bulk_request.total_records} records. #{@bulk_request.failed_records} failed."
    )
    dispatch_catalog_updated_event(
      added_count: added_product_ids.size,
      updated_count: updated_product_ids.size,
      deleted_count: 0,
      added_product_ids: added_product_ids,
      updated_product_ids: updated_product_ids,
      deleted_product_ids: []
    )
  end

  def fail_bulk_request(error_message)
    @bulk_request.update!(status: 'FAILED', progress: 0.0, error_message: error_message)
  end

  def handle_failed_processing(excel_result, media_result)
    error_msg = []
    error_msg << "Excel: #{excel_result[:error]}" unless excel_result[:success]
    error_msg << "Media: #{media_result[:error]}" unless media_result[:success]

    fail_bulk_request(error_msg.join('; '))
  end

  def dispatch_catalog_updated_event(added_count:, updated_count:, deleted_count:, added_product_ids:, updated_product_ids:, deleted_product_ids:)
    Rails.configuration.dispatcher.dispatch(
      PRODUCT_CATALOG_UPDATED,
      Time.zone.now,
      account: @account,
      added_count: added_count,
      updated_count: updated_count,
      deleted_count: deleted_count,
      added_product_ids: added_product_ids,
      updated_product_ids: updated_product_ids,
      deleted_product_ids: deleted_product_ids
    )
  end

  def handle_error(error)
    @bulk_request.update!(
      status: 'FAILED',
      error_message: error.message
    )

    # Cleanup temp file on error
    cleanup_temp_file

    # Log error for debugging
    Rails.logger.error("Product catalog bulk upload failed: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    # Broadcast error notification
    broadcast_error_notification(error)
  end

  def cleanup_temp_file
    return unless @file_path.present?

    File.delete(@file_path) if File.exist?(@file_path)
    Rails.logger.info("Cleaned up temp file: #{@file_path}")
  rescue StandardError => e
    Rails.logger.warn("Failed to cleanup temp file #{@file_path}: #{e.message}")
  end

  def broadcast_completion_notification
    # Broadcast to user's channel for real-time UI updates
    ActionCable.server.broadcast(
      "bulk_processing:#{@account.id}:#{@user.id}",
      {
        type: 'bulk_processing_completed',
        bulk_request_id: @bulk_request.id,
        status: @bulk_request.status,
        processed_records: @bulk_request.processed_records,
        failed_records: @bulk_request.failed_records,
        total_records: @bulk_request.total_records
      }
    )
  end

  def broadcast_error_notification(error)
    ActionCable.server.broadcast(
      "bulk_processing:#{@account.id}:#{@user.id}",
      {
        type: 'bulk_processing_failed',
        bulk_request_id: @bulk_request.id,
        error: error.message
      }
    )
  end
end
