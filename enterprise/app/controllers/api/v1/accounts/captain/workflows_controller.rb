class Api::V1::Accounts::Captain::WorkflowsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Workflow) }
  before_action :set_assistant
  before_action :set_workflow, only: [:show, :update, :destroy, :executions]

  def index
    @workflows = assistant_workflows.order(created_at: :desc)
  end

  def show; end

  def create
    @workflow = assistant_workflows.create!(workflow_params.merge(account: Current.account))
  end

  def update
    @workflow.update!(workflow_params)
  end

  def destroy
    @workflow.destroy
    head :no_content
  end

  def executions
    @executions = @workflow.executions.order(created_at: :desc).limit(50)
  end

  private

  def set_assistant
    @assistant = account_assistants.find(params[:assistant_id])
  end

  def account_assistants
    @account_assistants ||= Current.account.captain_assistants
  end

  def set_workflow
    @workflow = assistant_workflows.find(params[:id])
  end

  def assistant_workflows
    @assistant.workflows
  end

  def workflow_params
    permitted = params.require(:workflow).permit(:name, :description, :trigger_event, :enabled, trigger_conditions: {})
    permitted[:nodes] = params[:workflow][:nodes] if params[:workflow][:nodes].present?
    permitted[:edges] = params[:workflow][:edges] if params[:workflow][:edges].present?
    permitted
  end
end
