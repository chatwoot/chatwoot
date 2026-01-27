class Api::V1::Accounts::ProductCatalogsController < Api::V1::Accounts::BaseController
  include Events::Types

  before_action :product_catalog, except: [:index, :create, :bulk_upload, :bulk_delete, :export, :export_all, :download_export, :download_template]
  before_action :check_authorization
  before_action :check_rate_limit, only: [:bulk_upload, :export_all]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50 # Default 50 products per page
    search_query = params[:q]

    # Base query for current account
    base_query = Current.account.product_catalogs

    # Apply search if query parameter is present
    @product_catalogs = if search_query.present?
                          base_query.search_by_text(search_query)
                                    .includes(:product_media)
                                    .order('product_catalogs.created_at DESC')
                                    .page(page)
                                    .per(per_page)
                        else
                          base_query.includes(:product_media)
                                    .order(created_at: :desc)
                                    .page(page)
                                    .per(per_page)
                        end

    @total_count = @product_catalogs.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
  end

  def show; end

  def create
    @product_catalog = Current.account.product_catalogs.create!(product_catalog_params)
  end

  def update
    @product_catalog.update!(product_catalog_params)
  end

  def destroy
    @product_catalog.destroy!
    head :ok
  end

  def toggle_visibility
    @product_catalog.update!(is_visible: !@product_catalog.is_visible)
    render :show
  end

  def bulk_upload
    uploaded_file = params[:file]

    unless uploaded_file.present?
      render json: { error: 'No file provided' }, status: :unprocessable_entity
      return
    end

    # Acquire validation lock atomically via Redis to prevent concurrent uploads for this account
    unless ProductCatalogs::RateLimiterService.acquire_validation_lock(Current.account.id)
      render json: { error: 'Another upload is being validated. Please wait a moment and try again.' }, status: :too_many_requests
      return
    end

    temp_file = nil
    begin
      # Security validation: Max file size 50MB
      max_file_size = 50.megabytes
      if uploaded_file.size > max_file_size
        render json: { error: 'File too large. Maximum size is 50MB.' }, status: :unprocessable_entity
        return
      end

      # Security validation: Only allow Excel files (.xlsx)
      allowed_content_types = [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-excel.sheet.macroEnabled.12'
      ]
      file_extension = File.extname(uploaded_file.original_filename).downcase

      unless file_extension == '.xlsx' && allowed_content_types.include?(uploaded_file.content_type)
        render json: { error: 'Invalid file type. Only Excel files (.xlsx) are allowed.' }, status: :unprocessable_entity
        return
      end

      # Security validation: Verify file magic bytes (xlsx files are ZIP archives starting with PK)
      uploaded_file.rewind
      magic_bytes = uploaded_file.read(4)
      uploaded_file.rewind
      unless magic_bytes == "PK\x03\x04"
        render json: { error: 'Invalid file format. The file does not appear to be a valid Excel file.' }, status: :unprocessable_entity
        return
      end

      # Security validation: Filename max 100 characters
      if uploaded_file.original_filename.length > 100
        render json: { error: 'Filename too long. Maximum 100 characters allowed.' }, status: :unprocessable_entity
        return
      end

      # Check if there's already an active processing request for this account
      active_request = Current.account.bulk_processing_requests
                              .where(entity_type: 'ProductCatalog')
                              .where(status: %w[PENDING PROCESSING])
                              .first

      if active_request
        render json: {
          error: 'A file is already being processed. Please wait for it to complete or cancel it first.',
          active_request_id: active_request.id
        }, status: :unprocessable_entity
        return
      end

      # Dismiss all previous bulk requests for ProductCatalog
      Current.account.bulk_processing_requests
             .where(entity_type: 'ProductCatalog')
             .where(dismissed_at: nil)
             .update_all(dismissed_at: Time.current)

      # Save file temporarily
      temp_file = save_uploaded_file(uploaded_file)

      # Create bulk processing request atomically
      @bulk_request = Current.account.bulk_processing_requests.create!(
        user: current_user,
        entity_type: 'ProductCatalog',
        file_name: uploaded_file.original_filename,
        status: 'PENDING'
      )

      # Queue the background job and extract the Sidekiq JID from the provider_job_id
      job = ProductCatalogs::ProcessBulkUploadJob.perform_later(@bulk_request.id, temp_file)

      # Get the actual Sidekiq JID from the job
      sidekiq_jid = job.provider_job_id
      @bulk_request.update!(job_id: sidekiq_jid)

      render json: { bulk_request_id: @bulk_request.id }, status: :accepted
    ensure
      # Always release the validation lock
      ProductCatalogs::RateLimiterService.release_validation_lock(Current.account.id)

      # Clean up temp file if operation failed (response already rendered with error)
      if temp_file && response.status != 202 && File.exist?(temp_file)
        FileUtils.rm_f(temp_file)
        Rails.logger.info "Cleaned up temp file after validation failure: #{temp_file}"
      end
    end
  end

  def bulk_delete
    ids = params[:ids]

    unless ids.present? && ids.is_a?(Array)
      render json: { error: 'No product IDs provided' }, status: :unprocessable_entity
      return
    end

    deleted_product_ids, deleted_count = destroy_products_with_skip_callbacks(ids)
    dispatch_bulk_delete_event(deleted_product_ids, deleted_count)

    head :ok
  end

  def export
    ids = params[:ids]

    unless ids.present? && ids.is_a?(Array)
      render json: { error: 'No product IDs provided' }, status: :unprocessable_entity
      return
    end

    # Get products to export
    products = Current.account.product_catalogs.where(id: ids).includes(:product_media)

    # Generate Excel file
    excel_data = ProductCatalogs::ExcelExporterService.new(products).export

    send_data excel_data,
              filename: "products_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  def download_template
    # Generate template Excel file
    excel_data = ProductCatalogs::ExcelTemplateService.new.generate

    send_data excel_data,
              filename: 'product_catalog_template.xlsx',
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  def export_all
    # Check if there's already an active request (upload or export) for this account
    active_request = Current.account.bulk_processing_requests
                            .where(entity_type: 'ProductCatalog')
                            .where(status: %w[PENDING PROCESSING])
                            .first

    if active_request
      error_msg = active_request.operation_type == 'EXPORT' ?
        'An export is already being processed. Please wait for it to complete.' :
        'An upload is already being processed. Please wait for it to complete before exporting.'
      render json: {
        error: error_msg,
        active_request_id: active_request.id
      }, status: :unprocessable_entity
      return
    end

    # Dismiss all previous export requests for ProductCatalog
    Current.account.bulk_processing_requests
           .where(entity_type: 'ProductCatalog', operation_type: 'EXPORT')
           .where(dismissed_at: nil)
           .update_all(dismissed_at: Time.current)

    # Create bulk processing request for export
    @bulk_request = Current.account.bulk_processing_requests.create!(
      user: current_user,
      entity_type: 'ProductCatalog',
      operation_type: 'EXPORT',
      file_name: "product_catalog_full_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
      status: 'PENDING'
    )

    # Queue the background job
    job = ProductCatalogs::ProcessFullExportJob.perform_later(@bulk_request.id)

    # Get the actual Sidekiq JID from the job
    sidekiq_jid = job.provider_job_id
    @bulk_request.update!(job_id: sidekiq_jid)

    render json: { bulk_request_id: @bulk_request.id }, status: :accepted
  end

  def download_export
    bulk_request = Current.account.bulk_processing_requests.find(params[:id])

    unless bulk_request.operation_export? && bulk_request.completed?
      render json: { error: 'Export not ready or not found' }, status: :not_found
      return
    end

    # Check for new multiple files format first, then fall back to legacy single file
    if bulk_request.export_files.attached? && bulk_request.export_files.any?
      download_multiple_export_files(bulk_request)
    elsif bulk_request.export_file.attached?
      download_single_export_file(bulk_request)
    else
      render json: { error: 'Export file not found' }, status: :not_found
    end
  end

  private

  def download_single_export_file(bulk_request)
    # Download file data before cleanup
    file_data = bulk_request.export_file.download
    file_name = bulk_request.file_name

    # Mark as dismissed and cleanup immediately (file downloaded successfully)
    bulk_request.update!(dismissed_at: Time.current)
    bulk_request.export_file.purge

    Rails.logger.info "Export file downloaded and cleaned up for bulk_request_id=#{bulk_request.id}"

    # Send the file
    send_data file_data,
              filename: file_name,
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  def download_multiple_export_files(bulk_request)
    require 'zip'

    files_count = bulk_request.export_files.count

    if files_count == 1
      # Single file - download directly as xlsx
      attachment = bulk_request.export_files.first
      file_data = attachment.download
      file_name = attachment.filename.to_s

      # Mark as dismissed and cleanup
      bulk_request.update!(dismissed_at: Time.current)
      bulk_request.export_files.purge

      Rails.logger.info "Export file downloaded and cleaned up for bulk_request_id=#{bulk_request.id}"

      send_data file_data,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    else
      # Multiple files - create ZIP
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      zip_filename = "product_catalog_export_#{timestamp}.zip"

      # Create ZIP file in memory
      zip_data = Zip::OutputStream.write_buffer do |zip|
        bulk_request.export_files.each do |attachment|
          zip.put_next_entry(attachment.filename.to_s)
          zip.write(attachment.download)
        end
      end
      zip_data.rewind

      # Mark as dismissed and cleanup all files
      bulk_request.update!(dismissed_at: Time.current)
      bulk_request.export_files.purge

      Rails.logger.info "Export files (#{files_count}) downloaded as ZIP and cleaned up for bulk_request_id=#{bulk_request.id}"

      send_data zip_data.read,
                filename: zip_filename,
                type: 'application/zip'
    end
  end

  def product_catalog
    @product_catalog ||= Current.account.product_catalogs.find(params[:id])
  end

  def product_catalog_params
    params.require(:product_catalog).permit(
      :industry,
      :product_service,
      :type,
      :subcategory,
      :list_price,
      :currency,
      :description,
      :payment_options,
      :financing_term,
      :interest_rate,
      :attributes,
      :brand,
      :model,
      :year,
      :is_visible,
      metadata: {}
    ).merge(
      created_by: current_user,
      updated_by: current_user
    )
  end

  def save_uploaded_file(uploaded_file)
    temp_dir = Rails.root.join('tmp', 'uploads')
    FileUtils.mkdir_p(temp_dir)

    # Sanitize filename to prevent path traversal attacks
    safe_filename = File.basename(uploaded_file.original_filename)
    temp_file_path = temp_dir.join("#{SecureRandom.uuid}_#{safe_filename}")

    File.open(temp_file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    temp_file_path.to_s
  end

  def check_rate_limit
    operation_type = action_name == 'bulk_upload' ? 'UPLOAD' : 'EXPORT'

    unless ProductCatalogs::RateLimiterService.acquire_lock(Current.account.id, operation_type)
      lock_info = ProductCatalogs::RateLimiterService.lock_info(Current.account.id)
      remaining = lock_info&.dig(:remaining_seconds) || ProductCatalogs::RateLimiterService::RATE_LIMIT_SECONDS

      render json: {
        error: "Rate limit exceeded. Please wait #{remaining} seconds before trying again.",
        retry_after: remaining,
        current_operation: lock_info&.dig(:operation_type)
      }, status: :too_many_requests
    end
  end

  def destroy_products_with_skip_callbacks(ids)
    products_to_delete = Current.account.product_catalogs.where(id: ids)
    deleted_product_ids = products_to_delete.pluck(:product_id)

    deleted_count = 0
    products_to_delete.find_each do |product|
      product.skip_catalog_callbacks = true
      product.destroy
      deleted_count += 1
    end

    [deleted_product_ids, deleted_count]
  end

  def dispatch_bulk_delete_event(deleted_product_ids, deleted_count)
    Rails.configuration.dispatcher.dispatch(
      PRODUCT_CATALOG_UPDATED,
      Time.zone.now,
      account: Current.account,
      added_count: 0,
      updated_count: 0,
      deleted_count: deleted_count,
      added_product_ids: [],
      updated_product_ids: [],
      deleted_product_ids: deleted_product_ids
    )
  end
end
