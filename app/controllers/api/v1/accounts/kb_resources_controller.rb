class Api::V1::Accounts::KbResourcesController < Api::V1::Accounts::BaseController
  before_action :kb_resource, only: %i[show update destroy toggle_visibility move]
  before_action :check_authorization

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50
    folder_path = normalize_folder_path(params[:folder_path] || '/')

    base_query = Current.account.kb_resources.includes(:product_catalogs)

    if params[:product_catalog_id].present?
      base_query = base_query.joins(:kb_resource_product_catalogs)
                             .where(kb_resource_product_catalogs: { product_catalog_id: params[:product_catalog_id] })
    end

    # When searching, search across ALL folders; otherwise filter by current folder
    @kb_resources = if params[:q].present?
                      base_query.where('name ILIKE ? OR file_name ILIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
                                .ordered.page(page).per(per_page)
                    else
                      base_query.where(folder_path: folder_path)
                                .ordered.page(page).per(per_page)
                    end

    @total_count = @kb_resources.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
    @current_folder = folder_path

    # Get subfolders from KbFolder model (only when not searching)
    @subfolders = if params[:q].present?
                    []
                  else
                    Current.account.kb_folders
                           .where(parent_path: folder_path)
                           .ordered
                           .pluck(:name, :full_path)
                           .map { |name, full_path| { name: name, path: full_path } }
                  end

    # Include storage info in response
    @storage_used = KbResource.storage_used_by_account(Current.account.id)
    @storage_limit = KbResource::MAX_STORAGE_PER_ACCOUNT
  end

  def show; end

  def create
    uploaded_file = params[:file]

    unless uploaded_file.present?
      render json: { error: 'No file provided' }, status: :unprocessable_entity
      return
    end

    # Check file size limit before uploading
    if uploaded_file.size > KbResource::MAX_FILE_SIZE
      render json: {
        error: "File exceeds maximum size of #{KbResource::MAX_FILE_SIZE / 1.megabyte}MB",
        max_size: KbResource::MAX_FILE_SIZE,
        file_size: uploaded_file.size
      }, status: :unprocessable_entity
      return
    end

    # Check storage limit before uploading
    remaining_storage = KbResource.storage_remaining_for_account(Current.account.id)
    if uploaded_file.size > remaining_storage
      render json: {
        error: 'Insufficient storage space',
        remaining_bytes: remaining_storage,
        file_size: uploaded_file.size
      }, status: :unprocessable_entity
      return
    end

    uploader = KbResources::S3UploaderService.new(account_id: Current.account.id)
    upload_result = uploader.upload(uploaded_file)

    begin
      @kb_resource = Current.account.kb_resources.new(
        name: params[:name].presence || upload_result[:file_name],
        description: params[:description],
        folder_path: normalize_folder_path(params[:folder_path] || '/'),
        file_name: upload_result[:file_name],
        s3_key: upload_result[:s3_key],
        content_type: upload_result[:content_type],
        file_size: upload_result[:file_size],
        created_by: current_user
      )

      # Skip automatic callback to dispatch event after associations are set
      @kb_resource.skip_create_callback = true
      @kb_resource.save!

      # Handle product catalog associations
      if params[:product_catalog_ids].present?
        product_catalog_ids = Array(params[:product_catalog_ids]).map(&:to_i).uniq
        @kb_resource.product_catalog_ids = product_catalog_ids
      end

      # Reload to get fresh associations and dispatch event with current state
      @kb_resource.reload
      @kb_resource.dispatch_create_event!

      render :show, status: :created
    rescue StandardError => e
      # Clean up S3 file if database creation fails
      uploader.delete(upload_result[:s3_key])
      raise e
    end
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    # Skip automatic callback to dispatch event after all updates (including associations)
    @kb_resource.skip_update_callback = true

    # Track old product_ids before update
    old_product_ids = @kb_resource.product_catalogs.pluck(:product_id)

    @kb_resource.update!(
      kb_resource_params.except(:product_catalog_ids).merge(updated_by: current_user)
    )

    # Save changes before reload (excluding updated_at)
    tracked_changes = @kb_resource.previous_changes.except('updated_at')

    # Handle product catalog associations if provided
    if params[:kb_resource].key?(:product_catalog_ids)
      product_catalog_ids = Array(params[:kb_resource][:product_catalog_ids]).map(&:to_i).uniq
      @kb_resource.product_catalog_ids = product_catalog_ids

      # Track product_ids change if different
      new_product_ids = ProductCatalog.where(id: product_catalog_ids).pluck(:product_id)
      if old_product_ids.sort != new_product_ids.sort
        tracked_changes['product_ids'] = [old_product_ids.sort, new_product_ids.sort]
      end
    end

    # Reload to get fresh associations and dispatch event with current state
    @kb_resource.reload
    @kb_resource.dispatch_update_event!(tracked_changes)

    render :show
  end

  def destroy
    s3_key = @kb_resource.s3_key
    @kb_resource.destroy!

    # Delete from S3 in background
    KbResources::S3UploaderService.new(account_id: Current.account.id).delete(s3_key)

    head :ok
  end

  def toggle_visibility
    @kb_resource.update!(is_visible: !@kb_resource.is_visible, updated_by: current_user)
    render :show
  end

  def storage_info
    render json: {
      storage_used: KbResource.storage_used_by_account(Current.account.id),
      storage_limit: KbResource::MAX_STORAGE_PER_ACCOUNT,
      storage_remaining: KbResource.storage_remaining_for_account(Current.account.id)
    }
  end

  def move
    new_folder_path = normalize_folder_path(params[:folder_path])
    @kb_resource.update!(folder_path: new_folder_path, updated_by: current_user)
    render :show
  end

  def bulk_move
    resource_ids = Array(params[:resource_ids]).map(&:to_i)
    new_folder_path = normalize_folder_path(params[:folder_path])

    Current.account.kb_resources.where(id: resource_ids).update_all(
      folder_path: new_folder_path,
      updated_by_id: current_user.id,
      updated_at: Time.current
    )

    head :ok
  end

  def create_folder
    folder_name = params[:name]&.strip
    parent_path = normalize_folder_path(params[:parent_path] || params[:folder_path]&.gsub(%r{/[^/]+$}, '') || '/')

    if folder_name.blank?
      render json: { error: 'Folder name is required' }, status: :unprocessable_entity
      return
    end

    @kb_folder = Current.account.kb_folders.create!(
      name: folder_name,
      parent_path: parent_path,
      created_by: current_user
    )

    render json: {
      id: @kb_folder.id,
      name: @kb_folder.name,
      path: @kb_folder.full_path,
      parent_path: @kb_folder.parent_path,
      created_at: @kb_folder.created_at,
      storage_used: KbResource.storage_used_by_account(Current.account.id)
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def delete_folder
    folder_path = normalize_folder_path(params[:folder_path])
    force_delete = params[:force] == 'true' || params[:force] == true

    # Count contents recursively
    resources_count = count_resources_recursively(folder_path)
    subfolders_count = count_subfolders_recursively(folder_path)

    if (resources_count.positive? || subfolders_count.positive?) && !force_delete
      # Return info about contents so frontend can show confirmation
      render json: {
        error: 'Folder is not empty',
        requires_confirmation: true,
        resources_count: resources_count,
        subfolders_count: subfolders_count,
        folder_name: folder_path.split('/').last
      }, status: :unprocessable_entity
      return
    end

    # Force delete: recursively delete all contents
    if force_delete
      delete_folder_contents_recursively(folder_path)
    end

    folder = Current.account.kb_folders.find_by!(full_path: folder_path)
    folder.destroy!

    render json: {
      deleted_resources: resources_count,
      deleted_subfolders: subfolders_count,
      storage_used: KbResource.storage_used_by_account(Current.account.id)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Folder not found' }, status: :not_found
  end

  def tree
    # Get all folders for this account
    all_folders = Current.account.kb_folders.ordered.map do |folder|
      {
        id: folder.id,
        name: folder.name,
        path: folder.full_path,
        parent_path: folder.parent_path,
        type: 'folder'
      }
    end

    # Get all resources for this account with product catalogs
    all_resources = Current.account.kb_resources.includes(:product_catalogs).ordered.map do |resource|
      {
        id: resource.id,
        name: resource.name,
        description: resource.description,
        file_name: resource.file_name,
        folder_path: resource.folder_path,
        content_type: resource.content_type,
        file_size: resource.file_size,
        is_visible: resource.is_visible,
        s3_url: resource.presigned_url,
        created_at: resource.created_at,
        updated_at: resource.updated_at,
        product_catalog_ids: resource.product_catalog_ids,
        product_catalogs: resource.product_catalogs.map do |catalog|
          {
            id: catalog.id,
            product_id: catalog.product_id,
            productName: catalog.productName,
            type: catalog.type,
            industry: catalog.industry
          }
        end,
        type: 'file'
      }
    end

    render json: {
      folders: all_folders,
      resources: all_resources,
      storage_used: KbResource.storage_used_by_account(Current.account.id),
      storage_limit: KbResource::MAX_STORAGE_PER_ACCOUNT
    }
  end

  private

  def kb_resource
    @kb_resource ||= Current.account.kb_resources.find(params[:id])
  end

  def kb_resource_params
    params.require(:kb_resource).permit(:name, :description, :is_visible, :folder_path, product_catalog_ids: [])
  end

  def normalize_folder_path(path)
    return '/' if path.blank?

    # Ensure path starts with / and doesn't end with / (except root)
    normalized = "/#{path}".gsub(%r{/+}, '/').chomp('/')
    normalized.presence || '/'
  end

  def extract_immediate_subfolder(current_path, full_path)
    # Remove current path prefix
    prefix = current_path == '/' ? '' : current_path
    remaining = full_path.sub(%r{^#{Regexp.escape(prefix)}/}, '')

    # Get only the first segment (immediate subfolder)
    first_segment = remaining.split('/').first
    return nil if first_segment.blank?

    first_segment
  end

  # Count all resources in folder and subfolders recursively
  def count_resources_recursively(folder_path)
    # Resources directly in this folder
    direct_count = Current.account.kb_resources.where(folder_path: folder_path).count

    # Resources in subfolders (using LIKE for path prefix matching)
    subfolder_prefix = folder_path == '/' ? '/%' : "#{folder_path}/%"
    nested_count = Current.account.kb_resources.where('folder_path LIKE ?', subfolder_prefix).count

    direct_count + nested_count
  end

  # Count all subfolders recursively
  def count_subfolders_recursively(folder_path)
    # Direct subfolders
    direct_count = Current.account.kb_folders.where(parent_path: folder_path).count

    # Nested subfolders (using LIKE for path prefix matching)
    subfolder_prefix = folder_path == '/' ? '/%' : "#{folder_path}/%"
    nested_count = Current.account.kb_folders.where('parent_path LIKE ?', subfolder_prefix).count

    direct_count + nested_count
  end

  # Delete all contents of a folder recursively
  def delete_folder_contents_recursively(folder_path)
    uploader = KbResources::S3UploaderService.new(account_id: Current.account.id)

    # Find all resources in this folder and subfolders
    subfolder_prefix = folder_path == '/' ? '/%' : "#{folder_path}/%"
    resources_to_delete = Current.account.kb_resources
                                         .where('folder_path = ? OR folder_path LIKE ?', folder_path, subfolder_prefix)

    # Delete each resource from S3 and database
    resources_to_delete.find_each do |resource|
      uploader.delete(resource.s3_key) if resource.s3_key.present?
      resource.destroy!
    end

    # Delete all subfolders (deepest first to avoid foreign key issues)
    subfolders = Current.account.kb_folders
                                .where('parent_path = ? OR parent_path LIKE ?', folder_path, subfolder_prefix)
                                .order('LENGTH(full_path) DESC')

    subfolders.destroy_all
  end
end
