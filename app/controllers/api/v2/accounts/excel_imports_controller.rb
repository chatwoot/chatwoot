class Api::V2::Accounts::ExcelImportsController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  # before_action :validate_file_size, only: [:create]
  MAX_FILE_SIZE_MB = 5

  # Shows the status and metadata of a specific Excel import
  def show
    import_service = find_import_service
    return unless import_service

    render json: {
      success: true,
      import: import_service.import_status
    }
  end

  # Handles processing array of data objects sent from frontend
  def create
    knowledge_source = @ai_agent.knowledge_source
    unless knowledge_source
      render json: { error: 'Knowledge source not found' }, status: :not_found
      return
    end

    data_array = params[:data]
    file_name = sanitize_filename(params[:file_name])
    file_type = sanitize_mime_type(params[:file_type])
    file_size = params[:file_size].to_i if params[:file_size]
    description = sanitize_description(params[:description])

    if data_array.blank? || !data_array.is_a?(Array)
      render json: { error: 'Data must be a non-empty array' }, status: :bad_request
      return
    end

    # Backend check: limit JSON data array to 5 MB
    if data_array.to_json.bytesize > MAX_FILE_SIZE_MB.megabytes
      render json: { error: 'Data array exceeds maximum allowed size (5 MB)' }, status: :unprocessable_entity
      return
    end

    if file_name.blank?
      render json: { error: 'File name is required' }, status: :bad_request
      return
    end

    if file_type.blank?
      render json: { error: 'File type is required' }, status: :bad_request
      return
    end

    if file_size.blank? || !file_size.is_a?(Integer) || file_size <= 0
      render json: { error: 'File size must be a positive integer' }, status: :bad_request
      return
    end

    import_service = ExcelImport::ExcelImportService.new(
      account_id: Current.account.id,
      store_id: knowledge_source.store_id,
      file_name: file_name,
      data_array: data_array,
      description: description
    )

    result = import_service.process_data_import

    # Rails.logger.info "Excel import completed: #{result[:import_id]}"

    file = OpenStruct.new(
      content_type: file_type,
      size: file_size,
      file_name: file_name
    )

    knowledge_source.add_excel_file!(file: file, result: result)

    if result[:success]
      render json: {
        success: true,
        import_id: result[:import_id],
        total_rows: result[:total_rows],
        message: result[:message]
      }, status: :created
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  end

  # Deletes the import record and all associated rows
  def destroy
    file_id = params[:id] # PostgreSQL file ID

    # Find the knowledge source file first
    knowledge_source_file = @ai_agent.knowledge_source.knowledge_source_files.find_by(id: file_id)

    unless knowledge_source_file
      render json: { error: 'File not found' }, status: :not_found
      return
    end

    import_service = find_import_service
    return unless import_service

    begin
      # Delete the MongoDB import record and associated rows
      import_service.destroy

      # Delete the PostgreSQL knowledge source file record
      knowledge_source_file.destroy

      render json: {
        success: true,
        message: 'Import deleted successfully'
      }
    rescue StandardError => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # Downloads the data as JSON (no longer an Excel file)
  def download
    import_service = find_import_service
    return unless import_service

    begin
      data = import_service.get_all_data

      send_data data.to_json,
                filename: "#{import_service.file_name || 'data_export'}.json",
                type: 'application/json',
                disposition: 'attachment'
    rescue StandardError => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # Finds the ExcelImportService for the given import_id, ensuring it belongs to the current account
  def find_import_service
    file_id = params[:id] # This is the PostgreSQL file ID

    # Find the knowledge source file to get the loader_id (MongoDB import_id)
    knowledge_source_file = @ai_agent.knowledge_source.knowledge_source_files.find_by(id: file_id)

    unless knowledge_source_file
      render json: { error: 'File not found' }, status: :not_found
      return nil
    end

    # The loader_id contains the MongoDB import_id for Excel files
    import_id = knowledge_source_file.loader_id

    unless import_id
      render json: { error: 'Import ID not found for this file' }, status: :not_found
      return nil
    end

    begin
      import_service = ExcelImport::ExcelImportService.find(import_id)

      # Check if import belongs to current account
      unless import_service.account_id == Current.account.id
        render json: { error: 'Import not found' }, status: :not_found
        return nil
      end

      import_service
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: 'Import not found' }, status: :not_found
      nil
    end
  end

  # def validate_file_size
  #   uploaded_file = params[:file]

  #   if uploaded_file.nil?
  #     render json: { error: I18n.t('ai_agents.knowledge_source.file_size_error') }, status: :unprocessable_entity
  #     return
  #   end

  #   return unless uploaded_file.size > MAX_FILE_SIZE_MB.megabytes

  #   render json: { error: I18n.t('ai_agents.knowledge_source.file_size_error') }, status: :unprocessable_entity
  # end

  private

  def sanitize_filename(filename)
    return nil if filename.blank?

    # Remove dangerous characters and limit length
    sanitized = filename.to_s.gsub(/[^a-zA-Z0-9._-]/, '_').strip
    sanitized = sanitized[0..255] # Limit length
    sanitized.presence
  end

  def sanitize_mime_type(mime_type)
    return nil if mime_type.blank?

    # Whitelist allowed mime types
    allowed_types = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
      'text/csv'
    ]

    mime_type.to_s.strip.downcase if allowed_types.include?(mime_type.to_s.strip.downcase)
  end

  def sanitize_description(description)
    return nil if description.blank?

    # Remove potentially harmful characters and limit length
    sanitized = description.to_s.strip
    sanitized = sanitized[0..1000] # Limit to 1000 characters
    sanitized.presence
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
