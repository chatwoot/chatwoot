require 'csv'

class Api::V1::Accounts::DataImportsController < Api::V1::Accounts::BaseController
  DATA_IMPORT_FEATURE = 'data_import'.freeze

  before_action :ensure_data_import_feature_enabled
  before_action :set_data_import, only: [:show, :start, :abandon, :error_logs, :skip_logs]
  before_action :check_authorization

  def index
    @data_imports = policy_scope(Current.account.data_imports).includes(:initiated_by).order(created_at: :desc)
    data_import_ids = @data_imports.map(&:id)
    @import_errors_counts = DataImportError.non_skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
    @skip_logs_counts = DataImportError.skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
  end

  def show
    render_show
  end

  def validate_source
    totals = validate_intercom_source
    render json: { valid: true, totals: totals }
  rescue DataImports::Intercom::Client::AuthenticationError
    render_source_validation_error('We could not validate this Intercom access key. Check the key and its permissions.')
  rescue DataImports::Intercom::Client::Error
    render_source_validation_error('Intercom could not be reached. Please try again.')
  rescue ArgumentError => e
    render_source_validation_error(e.message)
  end

  def create
    @data_import = creation_service.perform
    unless @data_import
      render json: { message: 'Another data import is already in progress.' }, status: :unprocessable_entity
      return
    end

    DataImports::Intercom::ImportJob.perform_later(@data_import, @data_import.active_intercom_import_run_id)
    render_show
  rescue DataImports::Intercom::Client::AuthenticationError
    render_source_validation_error('We could not validate this Intercom access key. Check the key and its permissions.')
  rescue DataImports::Intercom::Client::Error
    render_source_validation_error('Intercom could not be reached. Please try again.')
  rescue ArgumentError => e
    render_source_validation_error(e.message)
  end

  def start
    restart_service = DataImports::Intercom::RestartService.new(account: Current.account, data_import: @data_import)
    restart_result = restart_service.perform
    @data_import = restart_service.data_import
    if restart_result == :access_token_missing
      render json: { message: 'The Intercom access key for this import is unavailable.' }, status: :unprocessable_entity
      return
    end

    DataImports::Intercom::ImportJob.perform_later(@data_import, @data_import.active_intercom_import_run_id) if restart_result == :enqueue
    render_show
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

  private

  def ensure_data_import_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?(DATA_IMPORT_FEATURE)
  end

  def set_data_import
    @data_import = Current.account.data_imports.find(params[:id])
  end

  def check_authorization
    authorize(@data_import || DataImport)
  end

  def permitted_params
    params.permit(:name, :source_provider, :access_token, import_types: [])
  end

  def creation_service
    DataImports::Intercom::CreationService.new(
      account: Current.account,
      initiated_by: Current.user,
      source_params: permitted_params.to_h
    )
  end

  def import_types
    return DataImports::Intercom::Importer::DEFAULT_IMPORT_TYPES unless permitted_params.key?(:import_types)

    Array(permitted_params[:import_types]).compact_blank
  end

  def validate_intercom_source
    raise ArgumentError, 'Unsupported import source.' unless permitted_params[:source_provider] == 'intercom'

    DataImports::Intercom::CredentialsValidator.new(
      access_token: permitted_params[:access_token],
      import_types: import_types
    ).perform
  end

  def render_source_validation_error(message)
    render json: { valid: false, message: message }, status: :unprocessable_entity
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
    CSV.generate(headers: true) do |csv|
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
