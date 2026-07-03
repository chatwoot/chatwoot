require 'csv'

class Api::V1::Accounts::DataImportsController < Api::V1::Accounts::BaseController
  IMPORT_ERRORS_PER_PAGE = 15
  SKIP_LOG_SOURCE_OBJECT_TYPES = %w[contact conversation message].freeze
  SKIP_LOGS_PER_PAGE = 15

  before_action :set_data_import, only: [:show, :start, :abandon, :skip_logs]
  before_action :check_authorization

  def index
    @data_imports = policy_scope(Current.account.data_imports).includes(:initiated_by).order(created_at: :desc)
    data_import_ids = @data_imports.map(&:id)
    @import_errors_counts = DataImportError.non_skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
    @skip_logs_counts = DataImportError.skip_logs.where(data_import_id: data_import_ids).group(:data_import_id).count
    @items_counts = DataImportItem.where(data_import_id: data_import_ids).group(:data_import_id).count
  end

  def show
    set_import_errors_page
    set_skip_logs_page
  end

  def create
    @data_import, enqueue_import = find_or_create_intercom_import
    DataImports::Intercom::ImportJob.perform_later(@data_import) if enqueue_import
    render :show
  end

  def start
    restart_result = prepare_intercom_import_restart
    if restart_result == :intercom_disconnected
      render json: { message: 'Intercom is not connected.' }, status: :unprocessable_entity
      return
    end

    DataImports::Intercom::ImportJob.perform_later(@data_import) if restart_result == :enqueue
    render :show
  end

  def abandon
    @data_import.update!(status: :abandoned, abandoned_at: Time.current) if @data_import.abandonable?
    render :show
  end

  def skip_logs
    send_data(
      skip_logs_csv,
      filename: "data-import-#{@data_import.id}-skip-logs.csv",
      type: 'text/csv'
    )
  end

  private

  def intercom_import_attributes(hook)
    {
      name: permitted_params[:name].presence || 'Intercom import',
      data_type: 'intercom',
      source_type: 'integration',
      source_provider: 'intercom',
      import_types: import_types,
      initiated_by: Current.user,
      integration_hook: hook,
      config: {
        create_source_bucket_inboxes: true,
        import_mode: 'historical'
      }
    }
  end

  def set_data_import
    @data_import = Current.account.data_imports.find(params[:id])
  end

  def check_authorization
    authorize(@data_import || DataImport)
  end

  def permitted_params
    params.permit(:name, import_types: [])
  end

  def import_types
    Array(permitted_params[:import_types]).compact_blank.presence || DataImports::Intercom::Importer::DEFAULT_IMPORT_TYPES
  end

  def find_or_create_intercom_import
    enqueue_import = false
    data_import = Current.account.with_lock do
      active_import = active_intercom_import
      next active_import if active_import

      hook = Current.account.hooks.enabled.find_by!(app_id: 'intercom')
      enqueue_import = true
      Current.account.data_imports.create!(intercom_import_attributes(hook))
    end

    [data_import, enqueue_import]
  end

  def prepare_intercom_import_restart
    Current.account.with_lock do
      @data_import.reload
      next :render_show unless @data_import.restartable?

      if (active_import = active_intercom_import)
        @data_import = active_import
        next :render_show
      end

      next :intercom_disconnected if @data_import.integration_hook.blank? || @data_import.integration_hook.disabled?

      @data_import.update!(status: :pending, abandoned_at: nil, completed_at: nil, last_error_at: nil)
      :enqueue
    end
  end

  def active_intercom_import
    Current.account.data_imports.find_by(
      data_type: 'intercom',
      source_provider: 'intercom',
      status: [:pending, :processing]
    )
  end

  def set_import_errors_page
    @import_errors_total_count = @data_import.import_errors.non_skip_logs.count
    @import_errors_per_page = IMPORT_ERRORS_PER_PAGE
    @import_errors_total_pages = [(@import_errors_total_count.to_f / @import_errors_per_page).ceil, 1].max
    @import_errors_page = params[:import_errors_page].to_i.clamp(1, @import_errors_total_pages)
    @import_errors = @data_import.import_errors.non_skip_logs
                                 .order(created_at: :desc)
                                 .offset((@import_errors_page - 1) * @import_errors_per_page)
                                 .limit(@import_errors_per_page)
  end

  def set_skip_logs_page
    skip_logs_scope = @data_import.import_errors.skip_logs
    @skip_logs_counts_by_type = skip_logs_scope.group(:source_object_type).count
    @skip_logs_source_object_type = skip_logs_source_object_type
    filtered_skip_logs = @skip_logs_source_object_type ? skip_logs_scope.where(source_object_type: @skip_logs_source_object_type) : skip_logs_scope

    @skip_logs_total_count = filtered_skip_logs.count
    @skip_logs_per_page = SKIP_LOGS_PER_PAGE
    @skip_logs_total_pages = [(@skip_logs_total_count.to_f / @skip_logs_per_page).ceil, 1].max
    @skip_logs_page = params[:skip_logs_page].to_i.clamp(1, @skip_logs_total_pages)
    @skip_logs = filtered_skip_logs.order(created_at: :desc)
                                   .offset((@skip_logs_page - 1) * @skip_logs_per_page)
                                   .limit(@skip_logs_per_page)
  end

  def skip_logs_source_object_type
    source_object_type = params[:skip_logs_type].presence
    return if source_object_type.blank?

    SKIP_LOG_SOURCE_OBJECT_TYPES.include?(source_object_type) ? source_object_type : nil
  end

  def skip_logs_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[created_at kind source_object_type source_object_id error_code message details]

      @data_import.import_errors.skip_logs.order(:created_at).find_each do |log|
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
