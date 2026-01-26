class Api::V1::Accounts::Notion::DatabasesController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    service = Notion::DatabasesService.new(Current.account)
    databases = service.list_databases

    render json: { databases: databases }
  rescue CustomExceptions::Notion::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def show
    service = Notion::DatabasesService.new(Current.account)
    schema = service.get_database_schema(params[:id])

    render json: schema
  rescue CustomExceptions::Notion::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def query
    service = Notion::DatabasesService.new(Current.account)
    records = service.query_database(params[:id], query_params)

    render json: { records: records, count: records.size }
  rescue CustomExceptions::Notion::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def check_authorization
    hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'notion')

    return if hook&.status == 'enabled'

    render json: { error: 'Notion integration not connected or not active' }, status: :unauthorized
  end

  def query_params
    params.permit(
      :limit,
      date_filters: [:id, :field_name, :operator, :days, :from_date, :to_date],
      select_filters: [:id, :field_name, :operator, :value]
    )
  end
end
