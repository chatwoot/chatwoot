class Api::V1::Accounts::Labels::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :fetch_label
  before_action :fetch_pipeline_stage, only: %i[update destroy]
  before_action :check_authorization

  def index
    @pipeline_stages = @label.pipeline_stages
  end

  def create
    @pipeline_stage = @label.pipeline_stages.create!(permitted_params)
  end

  def update
    @pipeline_stage.update!(permitted_params)
  end

  def destroy
    @pipeline_stage.destroy!
    head :ok
  end

  def reorder
    params[:positions].each do |stage_params|
      @label.pipeline_stages.find(stage_params[:id]).update!(position: stage_params[:position])
    end
    @pipeline_stages = @label.pipeline_stages.reload
    render :index
  end

  private

  def fetch_label
    @label = Current.account.labels.find(params[:label_id])
  end

  def fetch_pipeline_stage
    @pipeline_stage = @label.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:title, :position)
  end

  def check_authorization
    authorize @label, :update?
  end
end
