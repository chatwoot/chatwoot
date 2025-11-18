class Api::V1::Accounts::SalesPipelinesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_sales_pipeline, except: [:index, :create]
  before_action :check_authorization

  def index
    @sales_pipeline = current_account.sales_pipelines.first_or_create!
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
  end

  def show
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
  end

  def create
    @sales_pipeline = current_account.sales_pipelines.create!(permitted_params)
  end

  def update
    @sales_pipeline.update!(permitted_params)
  end

  def destroy
    @sales_pipeline.destroy!
    head :ok
  end

  private

  def fetch_sales_pipeline
    @sales_pipeline = current_account.sales_pipelines.find(params[:id])
  end

  def permitted_params
    params.require(:sales_pipeline).permit(:name)
  end
end