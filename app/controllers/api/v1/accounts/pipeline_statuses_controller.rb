# frozen_string_literal: true

class Api::V1::Accounts::PipelineStatusesController < Api::V1::Accounts::BaseController
  before_action :set_pipeline_params, only: %i[update destroy]

  def index
    @pipeline_statuses = @current_account.pipeline_statuses.order(:created_at)
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

  def pipeline_params
    params.require(:pipeline_status).permit(:id, :name)
  end
end
