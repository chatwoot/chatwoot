class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline
  before_action :fetch_stage, only: [:show, :update, :destroy]

  def index
    @stages = @pipeline.stages
  end

  def create
    @stage = @pipeline.stages.new(stage_params)
    authorize @stage
    @stage.save!
    render json: @stage
  end

  def update
    authorize @stage
    @stage.update!(stage_params)
    render json: @stage
  end

  def destroy
    authorize @stage
    @stage.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = @pipeline.stages.find(params[:id])
  end

  def stage_params
    params.require(:crm_stage).permit(:name, :stage_type, :display_order)
  end
end
