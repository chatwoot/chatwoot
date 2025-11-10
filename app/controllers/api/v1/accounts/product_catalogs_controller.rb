class Api::V1::Accounts::ProductCatalogsController < Api::V1::Accounts::BaseController
  before_action :product_catalog, except: [:index, :create, :bulk_upload, :bulk_delete, :export, :download_template]
  before_action :check_authorization

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50 # Default 50 products per page

    @product_catalogs = Current.account.product_catalogs
                               .includes(:product_media)
                               .order(created_at: :desc)
                               .page(page)
                               .per(per_page)

    @total_count = Current.account.product_catalogs.count
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

    # Create bulk processing request
    @bulk_request = Current.account.bulk_processing_requests.create!(
      user: current_user,
      entity_type: 'ProductCatalog',
      file_name: uploaded_file.original_filename,
      status: 'PENDING'
    )

    # Save file temporarily and trigger background job
    temp_file = save_uploaded_file(uploaded_file)

    # Queue the background job immediately
    job = ProductCatalogs::ProcessBulkUploadJob.perform_later(@bulk_request.id, temp_file)
    @bulk_request.update!(job_id: job.job_id)

    render json: { bulk_request_id: @bulk_request.id }, status: :accepted
  end

  def bulk_delete
    ids = params[:ids]

    unless ids.present? && ids.is_a?(Array)
      render json: { error: 'No product IDs provided' }, status: :unprocessable_entity
      return
    end

    # Delete products
    Current.account.product_catalogs.where(id: ids).destroy_all

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

  private

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

    temp_file_path = temp_dir.join("#{SecureRandom.uuid}_#{uploaded_file.original_filename}")

    File.open(temp_file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    temp_file_path.to_s
  end
end
