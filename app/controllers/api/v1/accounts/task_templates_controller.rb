class Api::V1::Accounts::TaskTemplatesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :task_template, except: [:index, :create]

  def index
    @task_templates = Current.account.task_templates.active.ordered.includes(:default_team)
  end

  def show; end

  def create
    @task_template = Current.account.task_templates.create!(task_template_params)
  end

  def update
    @task_template.update!(task_template_params)
  end

  def destroy
    @task_template.update!(active: false)
    head :ok
  end

  private

  def task_template
    @task_template = Current.account.task_templates.find(params[:id])
  end

  def task_template_params
    params.require(:task_template).permit(
      :key, :title, :description, :default_team_id, :default_priority,
      :default_due_offset_hours, :active, :position,
      metadata_schema: [:key, :label, :type],
      checklist_template: [:label, :done]
    )
  end

  def check_authorization
    authorize(TaskTemplate)
  end
end
