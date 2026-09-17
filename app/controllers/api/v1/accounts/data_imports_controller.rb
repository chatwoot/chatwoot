require 'csv'

class Api::V1::Accounts::DataImportsController < Api::V1::Accounts::BaseController
  before_action :set_data_import, only: [:show, :start, :retry_import, :abandon, :error_logs, :skip_logs, :rejected_rows]
  before_action :check_authorization

  def index
    @data_imports = policy_scope(Current.account.data_imports).includes(:initiated_by, :import_file_attachment, :failed_records_attachment)
                                                              .order(created_at: :desc)
    data_import_ids = @data_imports.map(&:id)
    @import_errors_counts = DataImportError.non_skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
    @skip_logs_counts = DataImportError.skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
  end

  def show
    render_show
  end

  def validate_source
    totals = DataImports::Source.validate_source(params[:source_provider], permitted_params.to_h.symbolize_keys, import_types)
    render json: { valid: true, totals: totals }
  rescue ArgumentError => e
    render_source_validation_error(e.message)
  rescue StandardError => e
    render_source_client_error(e)
  end

  def create
    @data_import = creation_service.perform
    unless @data_import
      render json: { message: 'Another data import is already in progress.' }, status: :unprocessable_entity
      return
    end

    enqueue_import(@data_import)
    render_show
  rescue ArgumentError => e
    render_source_validation_error(e.message)
  rescue StandardError => e
    render_source_client_error(e)
  end

  def start
    restart_service = DataImports::RestartService.new(account: Current.account, data_import: @data_import)
    restart_result = restart_service.perform
    @data_import = restart_service.data_import
    authorize @data_import, :show?
    if restart_result == :access_token_missing
      render json: { message: "The #{source_name} #{credential_name} for this import is unavailable." }, status: :unprocessable_entity
      return
    end

    enqueue_import(@data_import) if restart_result == :enqueue
    render_show
  end

  def retry_import
    retry_service = DataImports::RetryService.new(account: Current.account, data_import: @data_import)
    retry_result = retry_service.perform
    @data_import = retry_service.data_import

    case retry_result
    when :enqueue
      enqueue_import(@data_import)
      render_show
    when :not_stalled
      render json: { message: "This #{source_name} import is no longer stalled." }, status: :unprocessable_entity
    when :active_import_exists
      render json: { message: "Another #{source_name} import is already in progress." }, status: :unprocessable_entity
    when :access_token_missing
      render json: { message: "The #{source_name} #{credential_name} for this import is unavailable." }, status: :unprocessable_entity
    end
  end

  def abandon
    @data_import.abandon!
    render_show
  end

  def skip_logs
    send_data(
      skip_logs_csv,
      filename: "data-import-#{@data_import.id}-skip-logs.csv",
      type: 'text/csv'
    )
  end

  def error_logs
    send_data(
      error_logs_csv,
      filename: "data-import-#{@data_import.id}-error-logs.csv",
      type: 'text/csv'
    )
  end

  def rejected_rows
    return head :not_found unless @data_import.failed_records.attached?

    ActiveStorage::Current.set(url_options: { host: request.base_url }) do
      render json: { download_url: @data_import.failed_records.url(disposition: :attachment, expires_in: 5.minutes) }
    end
  end

  private

  def set_data_import
    @data_import = Current.account.data_imports.find(params[:id])
  end

  def check_authorization
    if %w[create validate_source].include?(action_name)
      provider = params[:source_provider]
      resource = Current.account.data_imports.new(data_type: provider == 'csv' ? 'contacts' : provider, source_provider: provider)
      authorize(resource)
    else
      authorize(@data_import || DataImport)
    end
  end

  def permitted_params
    raise ArgumentError, 'Import types must be an array.' if params.key?(:import_types) && !params[:import_types].is_a?(Array)

    params.permit(:name, :source_provider, :access_token, :domain, :import_file, import_types: [])
  end

  def creation_service
    DataImports::CreationService.new(
      account: Current.account,
      initiated_by: Current.user,
      source_params: permitted_params.to_h
    )
  end

  def import_types
    return DataImports::Source.import_types(params[:source_provider]) unless permitted_params.key?(:import_types)

    permitted_params[:import_types]
  end

  def source_class
    provider = @data_import&.source_provider || permitted_params[:source_provider]
    DataImports::Source.source_class(provider)
  end

  def source_name
    return 'Integration' unless DataImports::Source.supported?(@data_import&.source_provider || permitted_params[:source_provider])

    source_class::DISPLAY_NAME
  end

  def credential_name
    return 'credential' unless DataImports::Source.supported?(@data_import&.source_provider || permitted_params[:source_provider])

    source_class.credential_name
  end

  def enqueue_import(data_import)
    DataImports::Source.source_class(data_import.source_provider).import_job_class.perform_later(
      data_import,
      data_import.active_import_run_id
    )
  end

  def render_source_validation_error(message)
    render json: { valid: false, message: message }, status: :unprocessable_entity
  end

  def render_source_client_error(error)
    raise error unless DataImports::Source.supported?(@data_import&.source_provider || params[:source_provider])
    raise error unless source_class.client_error?(error)

    message = if source_class.authentication_error?(error)
                "We could not validate this #{source_name} #{credential_name}. Check the key and its permissions."
              else
                "#{source_name} could not be reached. Please try again."
              end
    render_source_validation_error(message)
  end

  def render_show
    @import_errors_finder = DataImportErrorFinder.new(@data_import)
    @skip_logs_finder = DataImportSkipLogFinder.new(@data_import, params)
    render :show
  end

  def skip_logs_csv
    logs_csv(@data_import.import_errors.skip_logs)
  end

  def error_logs_csv
    logs_csv(@data_import.import_errors.non_skip_logs)
  end

  def logs_csv(logs)
    CSVSafe.generate(headers: true) do |csv|
      csv << %w[created_at kind source_object_type source_object_id error_code message details]

      logs.order(:created_at).find_each do |log|
        csv << [
          log.created_at.iso8601,
          log.details['kind'],
          log.source_object_type,
          log.source_object_id,
          log.error_code,
          log.message,
          log.details.to_json
        ]
      end
    end
  end
end
