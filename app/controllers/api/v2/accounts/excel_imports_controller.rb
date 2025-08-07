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
    file_name = params[:file_name]

    if data_array.blank? || !data_array.is_a?(Array)
      render json: { error: 'Data must be a non-empty array' }, status: :bad_request
      return
    end

    if file_name.blank?
      render json: { error: 'File name is required' }, status: :bad_request
      return
    end

    import_service = ExcelImport::ExcelImportService.new(
      account_id: Current.account.id,
      store_id: knowledge_source.store_id,
      file_name: file_name,
      data_array: data_array
    )

    result = import_service.process_data_import

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
    import_service = find_import_service
    return unless import_service

    begin
      # Delete the import record and associated rows
      import_service.destroy

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
    import_id = params[:id]

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

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
