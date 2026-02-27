class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline, only: [:show, :update, :destroy]

  def index
    @pipelines = Current.account.crm_pipelines.includes(:stages)
  end

  def show
  end

  def create
    @pipeline = Current.account.crm_pipelines.new(pipeline_params)
    authorize @pipeline
    @pipeline.save!
    render :show
  end

  def update
    authorize @pipeline
    @pipeline.update!(pipeline_params)
    render :show
  end

  def destroy
    authorize @pipeline
    @pipeline.destroy!
    head :ok
  end

  private

  def pipeline_params
    params.require(:crm_pipeline).permit(:name, :display_order)
  end

  def fetch_pipeline
    @pipeline = Current.account.crm_pipelines.find(params[:id])
  end
end
