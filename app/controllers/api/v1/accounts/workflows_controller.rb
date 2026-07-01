class Api::V1::Accounts::WorkflowsController < Api::V1::Accounts::BaseController
  before_action :fetch_workflow, only: [:show, :update, :destroy]

  def index
    @workflows = Current.account.workflows
  end

  def show; end

  def create
    @workflow = Current.account.workflows.new(workflow_params)
    if @workflow.save
      render :show
    else
      render json: { error: @workflow.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @workflow.update(workflow_params)
      render :show
    else
      render json: { error: @workflow.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @workflow.destroy!
    head :ok
  end

  private

  def fetch_workflow
    @workflow = Current.account.workflows.find(params[:id])
  end

  def workflow_params
    params.require(:workflow).permit(:name, :description, :trigger_event, :active).tap do |whitelisted|
      whitelisted[:nodes] = params[:workflow][:nodes] if params[:workflow][:nodes].is_a?(Array)
      whitelisted[:edges] = params[:workflow][:edges] if params[:workflow][:edges].is_a?(Array)
    end
  end
end
