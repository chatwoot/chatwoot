class Api::V1::Accounts::DataExportsController < Api::V1::Accounts::BaseController
  before_action :set_data_export, only: [:show, :download, :rerun]
  before_action :check_authorization

  rescue_from ArgumentError, with: :invalid_export
  rescue_from CustomExceptions::CustomFilter::InvalidAttribute, CustomExceptions::CustomFilter::InvalidOperator,
              CustomExceptions::CustomFilter::InvalidQueryOperator, CustomExceptions::CustomFilter::InvalidValue, with: :invalid_export

  def index
    @data_exports = policy_scope(Current.account.data_exports).includes(:initiated_by, :export_file_attachment).order(created_at: :desc)
  end

  def show; end

  def create
    @data_export = creation_service(params.to_unsafe_h).perform
    render :show
  end

  def rerun
    previous = @data_export
    previous.with_lock do
      if previous.pending? || previous.processing?
        raise ArgumentError, 'This export is still running.' unless previous.stalled?

        previous.update!(status: :failed, completed_at: Time.current, active_run_id: nil,
                         error_message: 'The stalled export was replaced by a new export.')
      end
    end
    @data_export = creation_service(previous.export_options).perform
    render :show
  end

  def download
    return head :not_found unless @data_export.downloadable?

    ActiveStorage::Current.set(url_options: { host: request.base_url }) do
      render json: { download_url: @data_export.export_file.url(disposition: :attachment, expires_in: 5.minutes) }
    end
  end

  private

  def set_data_export
    @data_export = Current.account.data_exports.find(params[:id])
  end

  def check_authorization
    authorize(@data_export || DataExport)
  end

  def creation_service(options)
    DataExports::CreationService.new(account: Current.account, initiated_by: Current.user, options: options)
  end

  def invalid_export(error)
    render json: { message: error.message }, status: :unprocessable_entity
  end
end
