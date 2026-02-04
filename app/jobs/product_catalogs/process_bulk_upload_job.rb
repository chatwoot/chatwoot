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
    last_progress_update = Time.current

    # Calculate update frequency: for small batches update more often
    update_frequency = [total_products / 20, 10].max.clamp(1, 100)

    products.find_each do |product|
      # Check if bulk request status is still valid for processing
      @bulk_request.reload
      current_status = @bulk_request.status.upcase
      unless ['PENDING', 'PROCESSING'].include?(current_status)
        Rails.logger.warn("Stopping media processing - bulk request #{@bulk_request.id} status is #{current_status}")
        break
      end

      # Process media and collect per-URL errors
      product_media_errors = create_media_for_product(product)

      # If there were errors for this product, add them to the report
      if product_media_errors.any?
        @media_errors << {
          product_id: product.product_id,
          product_name: product.productName,
          media_errors: product_media_errors
        }
      end

      processed += 1

      # Update progress from 50% to 100% based on dynamic frequency or every 2 seconds
      should_update = (processed % update_frequency == 0) || (Time.current - last_progress_update > 2.seconds)
      if should_update
        progress = 50 + (processed.to_f / total_products * 50).round(2)
        @bulk_request.update!(
          progress: progress,
          updated_at: Time.current
        )
        last_progress_update = Time.current
        Rails.logger.info("Media processing progress: #{processed}/#{total_products} (#{progress}%)")
      end
    end

    # Final progress update to 100%
    @bulk_request.update!(
      progress: 100.0,
      updated_at: Time.current
    )

    # Save media errors to bulk request
    if @media_errors.any?
      existing_errors = @bulk_request.error_details || []
      @bulk_request.update!(error_details: existing_errors + @media_errors)
    end

    total_url_errors = @media_errors.sum { |e| e[:media_errors]&.size || 0 }
    {
      success: @media_errors.empty?,
      error: @media_errors.any? ? "#{@media_errors.count} products with media errors (#{total_url_errors} failed URLs)" : nil
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def create_media_for_product(product)
    # Clear existing media (S3 cleanup handled by after_destroy callback)
    product.all_product_media.destroy_all

    display_order = 0
    url_errors = []

    # Process photos
    Rails.logger.info "Processing #{product.photo_urls.length} photo URLs for product #{product.product_id}"
    product.photo_urls.each_with_index do |url, index|
      break if cancelled?

      result = process_single_media_url(product, url, 'photo', index, display_order)
      if result[:success]
        display_order += 1
      else
        url_errors << result[:error]
      end
    end

    # Process videos
    product.video_urls.each_with_index do |url, index|
      break if cancelled?

      result = process_single_media_url(product, url, 'video', index, display_order)
      if result[:success]
        display_order += 1
      else
        url_errors << result[:error]
      end
    end

    # Process PDFs/documents
    product.pdf_urls.each_with_index do |url, index|
      break if cancelled?

      result = process_single_media_url(product, url, 'document', index, display_order)
      if result[:success]
        display_order += 1
      else
        url_errors << result[:error]
      end
    end

    url_errors
  end

  def process_single_media_url(product, url, media_type, index, display_order)
    Rails.logger.info "Processing #{media_type} #{index + 1}: #{url}"

    # Validate URL format
    validation_error = validate_media_url(url, media_type)
    if validation_error
      return { success: false, error: build_media_error(media_type, url, index, validation_error) }
    end

    filename = extract_filename_from_url(url, media_type == 'photo' ? 'photo' : media_type, index)
    file_type = media_type == 'photo' ? :image : media_type.to_sym

    media = product.all_product_media.create!(
      file_type: file_type,
      file_url: url,
      file_name: filename,
      is_primary: media_type == 'photo' && index.zero?,
      display_order: display_order,
      user_id: @user.id,
      last_updated_by_id: @user.id
    )
    Rails.logger.info "Successfully created #{media_type.upcase} media with ID=#{media.id}"

    # Upload to S3 and check result
    s3_error = upload_media_to_s3(media)
    if s3_error
      return { success: false, error: build_media_error(media_type, url, index, s3_error) }
    end

    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    error_msg = e.record.errors.full_messages.join(', ')
    Rails.logger.error "Failed to create #{media_type.upcase} media: #{error_msg}"
    { success: false, error: build_media_error(media_type, url, index, humanize_validation_error(error_msg)) }
  rescue StandardError => e
    Rails.logger.error "Unexpected error processing #{media_type}: #{e.message}"
    { success: false, error: build_media_error(media_type, url, index, e.message) }
  end

  def validate_media_url(url, media_type)
    return 'URL is empty' if url.blank?

    # Remove query parameters for validation
    clean_url = url.to_s.split('?').first

    begin
      uri = URI.parse(clean_url)
      return 'URL must start with http:// or https://' unless %w[http https].include?(uri.scheme)
      return 'URL does not have a valid domain' if uri.host.blank?
    rescue URI::InvalidURIError
      return 'Invalid URL format'
    end

    # Validate extension
    filename = File.basename(uri.path)
    if filename.include?('.')
      extension = filename[filename.rindex('.')..-1].downcase
      unless valid_extension_for_prefix?(extension, media_type == 'photo' ? 'photo' : media_type)
        valid_exts = valid_extensions_for_type(media_type)
        return "Extension '#{extension}' not supported for #{media_type_label(media_type)}. Valid extensions: #{valid_exts.join(', ')}"
      end
    end

    nil
  end

  def build_media_error(media_type, url, index, error_message)
    {
      media_type: media_type_label(media_type),
      url: truncate_url(url),
      position: index + 1,
      error: error_message
    }
  end

  def media_type_label(media_type)
    case media_type
    when 'photo' then 'Photo'
    when 'video' then 'Video'
    when 'document' then 'Document'
    else media_type.capitalize
    end
  end

  def valid_extensions_for_type(media_type)
    case media_type
    when 'photo' then %w[.jpg .jpeg .png .gif .webp .svg]
    when 'video' then %w[.mp4 .avi .mov .wmv .flv .webm]
    when 'document' then %w[.pdf .doc .docx .xls .xlsx .txt]
    else []
    end
  end

  def humanize_validation_error(error_msg)
    # Convert technical validation errors to user-friendly messages
    human_message = case error_msg
                    when /file.?url.*blank/i
                      'File URL is empty'
                    when /file.?url.*invalid/i
                      'File URL is invalid'
                    when /file.?name.*blank/i
                      'Could not extract filename from URL'
                    when /file.?type.*blank/i
                      'Could not determine file type'
                    else
                      nil
                    end
    human_message ? "#{human_message} (#{error_msg})" : error_msg
  end

  def truncate_url(url, max_length: 80)
    return url if url.to_s.length <= max_length

    "#{url.to_s[0, max_length - 3]}..."
  end

  def upload_media_to_s3(media)
    media.update!(s3_status: 'on_going')

    s3_key = ProductCatalogs::S3KeyGeneratorService.new(
      account_id: @account.id,
      product_id: media.product_catalog.product_id || media.product_catalog.id,
      file_type: media.file_type,
      filename: media.file_name
    ).generate

    result = ProductCatalogs::S3StreamingUploaderService.new(
      url: media.original_url || media.file_url,
      s3_key: s3_key,
      file_type: media.file_type
    ).upload

    if result.success
      media.update!(
        s3_key: result.s3_key,
        s3_status: 'completed',
        s3_error: nil,
        s3_uploaded_at: Time.current,
        file_size: result.file_size,
        mime_type: result.mime_type
      )
      Rails.logger.info("Successfully uploaded media #{media.id} to S3: #{result.s3_key}")
      nil # No error
    else
      media.update!(s3_status: 'failed', s3_error: result.error)
      Rails.logger.error("Failed to upload media #{media.id} to S3: #{result.error}")
      humanize_s3_error(result.error)
    end
  rescue StandardError => e
    Rails.logger.error("Exception uploading media #{media.id} to S3: #{e.message}")
    media.update!(s3_status: 'failed', s3_error: e.message)
    humanize_s3_error(e.message)
  end

  def humanize_s3_error(error_msg)
    human_message = case error_msg.to_s.downcase
                    when /timeout|timed out/
                      'File download timed out. Please verify the URL is accessible'
                    when /404|not found/
                      'File not found at the provided URL'
                    when /403|forbidden|access denied/
                      'Access denied to file. Please verify the URL is public'
                    when /401|unauthorized/
                      'URL requires authentication. Please use a public URL'
                    when /connection refused|connection reset/
                      'Could not connect to server. Please verify the URL is correct'
                    when /ssl|certificate/
                      'SSL certificate error. Please verify the URL uses valid HTTPS'
                    when /too large|size limit|file.*large/
                      'File is too large to be processed'
                    when /invalid.*content|content.?type/
                      'File content type does not match the extension'
                    else
                      'Failed to upload file'
                    end
    "#{human_message} (#{error_msg.to_s.truncate(100)})"
  end

  def cancelled?
    @bulk_request.reload
    !%w[PENDING PROCESSING].include?(@bulk_request.status.upcase)
  end

  def extract_filename_from_url(url, default_prefix, index)
    require 'uri'
    require 'cgi'

    # Remove query parameters first (everything after ?)
    clean_url = url.to_s.split('?').first

    # Parse the clean URL
    uri = URI.parse(clean_url)
    path = uri.path

    # Get basename
    filename = File.basename(path)

    # URL decode the filename (e.g., "Desktop%20-%203.jpg" -> "Desktop - 3.jpg")
    filename = CGI.unescape(filename) if filename.present?

    # Extract extension using last index of '.'
    if filename.present? && filename.include?('.')
      last_dot_index = filename.rindex('.')
      extension = filename[last_dot_index..].downcase

      if valid_extension_for_prefix?(extension, default_prefix)
        return filename
      end
    end

    # Fallback to default naming
    "#{default_prefix}_#{index + 1}.#{default_extension_for_prefix(default_prefix)}"
  rescue StandardError => e
    Rails.logger.warn("Failed to extract filename from URL: #{url} - #{e.message}")
    "#{default_prefix}_#{index + 1}.#{default_extension_for_prefix(default_prefix)}"
  end

  def valid_extension_for_prefix?(extension, prefix)
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
