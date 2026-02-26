class Api::V1::Accounts::PipelinesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline, only: [:show, :update, :destroy]

  def index
    @pipelines = current_account.pipelines.includes(:pipeline_stages)
    render json: @pipelines.as_json(include: :pipeline_stages)
  end

  def show
    render json: @pipeline.as_json(include: :pipeline_stages)
  end

  def create
    @pipeline = current_account.pipelines.build(pipeline_params)
    if @pipeline.save
      render json: @pipeline, status: :created
    else
      render json: { errors: @pipeline.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pipeline.update(pipeline_params)
      render json: @pipeline
    else
      render json: { errors: @pipeline.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @pipeline.destroy
    head :no_content
  end

  private

  def fetch_pipeline
    @pipeline = current_account.pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, pipeline_stages_attributes: [:id, :name, :position, :_destroy])
  end
end
