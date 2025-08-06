class Api::V2::Accounts::ExcelImportsController < Api::V2::BaseController
  before_action :authenticate_user!
  before_action :check_authorization

  # Shows the status and metadata of a specific Excel import
  def show
    import_service = find_import_service
    return unless import_service

    render json: {
      success: true,
      import: import_service.get_import_status
    }
  end

  # Handles uploading and processing a new Excel file for import
  def create
    file = params[:file]

    return render json: { error: 'No file provided' }, status: :bad_request if file.blank?

    # Validate file type
    return render json: { error: 'Invalid file type. Please upload an Excel file (.xlsx, .xls)' }, status: :bad_request unless valid_excel_file?(file)

    # Read file data
    file_data = file.read
    file_name = file.original_filename
    content_type = file.content_type

    # Create import service
    import_service = ExcelImport::ExcelImportService.new(
      account_id: Current.account.id,
      file_data: file_data,
      file_name: file_name,
      content_type: content_type
    )

    # Process the import
    result = import_service.process_excel_import

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

  # Returns paginated parsed row data for a specific import (for preview in UI)
  def data
    import_service = find_import_service
    return unless import_service

    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 100
    per_page = [per_page, 1000].min # Limit max per_page to 1000

    result = import_service.get_parsed_data(page: page, per_page: per_page)

    render json: {
      success: true,
      **result
    }
  end

  # Processes and saves the final Excel file sent from the frontend (after user edits)
  def save_to_server
    import_service = find_import_service
    return unless import_service

    begin
      # In this workflow, the frontend sends the final Excel file, already edited by the user.
      # The backend should just process and save the file and its rows.
      result = import_service.process_excel_import

      if result[:success]
        render json: {
          success: true,
          message: 'Data saved to server successfully',
          processed_rows: result[:total_rows]
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  # Deletes the import record and all associated rows
  def destroy
    import_service = find_import_service
    return unless import_service

    begin
      # Delete the import record and associated rows
      # No need to delete physical file since it's stored in MongoDB
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

  # Downloads the original uploaded Excel file for a specific import
  def download
    import_service = find_import_service
    return unless import_service

    begin
      file_info = import_service.get_file_data

      send_data file_info[:file_data],
                filename: file_info[:file_name],
                type: file_info[:content_type],
                disposition: 'attachment'
    rescue StandardError => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  private

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

  # Checks if the uploaded file is a valid Excel file (.xlsx or .xls)
  def valid_excel_file?(file)
    allowed_types = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # .xlsx
      'application/vnd.ms-excel' # .xls
    ]

    return false unless allowed_types.include?(file.content_type)

    file_extension = File.extname(file.original_filename).downcase
    ['.xlsx', '.xls'].include?(file_extension)
  end

  # Ensures the user is authenticated (add more authorization logic as needed)
  def check_authorization
    # Add any specific authorization logic here
    # For now, just ensure user is authenticated
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end
end
