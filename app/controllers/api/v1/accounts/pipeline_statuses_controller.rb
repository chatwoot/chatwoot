# frozen_string_literal: true

class Api::V1::Accounts::PipelineStatusesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline_params, only: %i[update destroy]

  def index
    @pipeline_statuses = @current_account.pipeline_statuses.where(pipeline_type: pipeline_type_param)
  end

  def board
    @pipeline_type = pipeline_type_param
    board = PipelineBoard.new(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user,
      pipeline_type: @pipeline_type,
      params: params.permit!
    )
    @columns = board.columns(page: (params[:page] || 1).to_i)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def column_items
    @pipeline_type = pipeline_type_param
    board = PipelineBoard.new(
      account: Current.account,
      user: Current.user,
      account_user: Current.account_user,
      pipeline_type: @pipeline_type,
      params: params.permit!
    )
    result = board.column_items(params[:column_id].to_i, page: (params[:page] || 1).to_i)
    @items = result[:items]
    @total_count = result[:total_count]
    @has_more = result[:has_more]
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def reorder
    ordered_ids = params.require(:ordered_ids)
    ordered_ids.each_with_index do |id, index|
      @current_account.pipeline_statuses.where(id: id, pipeline_type: pipeline_type_param).update_all(position: index + 1) # rubocop:disable Rails/SkipsModelValidations
    end
    @pipeline_statuses = @current_account.pipeline_statuses.where(pipeline_type: pipeline_type_param)
    render :index
  end

  def create
    @pipeline_status = @current_account.pipeline_statuses.create!(pipeline_params)
  end

  def update
    @pipeline_status.update!(pipeline_params)
  end

  def destroy
    @pipeline_status.destroy!
    head :ok
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: e.record.errors[:base].first }, status: :unprocessable_entity
  end

  private

  def set_pipeline_params
    @pipeline_status = @current_account.pipeline_statuses.find(params[:id])

  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  def pipeline_type_param
    PipelineStatus.pipeline_types.key?(params[:pipeline_type]) ? params[:pipeline_type] : 'conversation'
  end

  def pipeline_params
    params.require(:pipeline_status).permit(:id, :name, :pipeline_type)
  end
end
