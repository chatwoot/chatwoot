class Api::V1::Accounts::TasksController < Api::V1::Accounts::BaseController
  include Sift

  sort_on :title, type: :string
  sort_on :status, type: :string
  sort_on :created_at, type: :datetime

  RESULTS_PER_PAGE = 15

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :search, :filter]
  before_action :task, only: [:show, :update, :destroy, :execute]

  def index
    @tasks = fetch_tasks(Current.account.tasks.includes(:creator, :assignee, :agent_bot))
    @tasks_count = @tasks.total_count
  end

  def search
    return render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank?

    tasks = Current.account.tasks.includes(:creator, :assignee, :agent_bot).where(
      'title ILIKE :search OR description ILIKE :search',
      search: "%#{params[:q].strip}%"
    )
    @tasks = fetch_tasks(tasks)
    @tasks_count = @tasks.total_count
  end

  def filter
    status_filter = params[:status]
    entity_type_filter = params[:entity_type]
    tasks = Current.account.tasks.includes(:creator, :assignee, :agent_bot)
    tasks = tasks.by_status(status_filter) if status_filter.present?
    tasks = tasks.where(entity_type: entity_type_filter) if entity_type_filter.present?

    @tasks_count = tasks.count
    @tasks = fetch_tasks(tasks)
  end

  def show; end

  def create
    @task = Current.account.tasks.build(task_params)
    @task.creator = Current.user

    if @task.save
      render :show, status: :created
    else
      render_validation_errors(@task.errors)
    end
  rescue ArgumentError => e
    render_error("Invalid value: #{e.message}", :unprocessable_entity)
  end

  def update
    if @task.update(task_params)
      render :show
    else
      render_validation_errors(@task.errors)
    end
  rescue ArgumentError => e
    render_error("Invalid value: #{e.message}", :unprocessable_entity)
  end

  def execute
    return render_error('Task is not pending', :unprocessable_entity) unless @task.pending?

    Tasks::ExecutorJob.perform_now(@task.id)
    render :show
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  private

  def task
    @task ||= Current.account.tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Task not found', :not_found)
  end

  def task_params
    params.require(:task).permit(
      :title,
      :description,
      :status,
      :action_type,
      :scheduled_at,
      :assignee_id,
      :agent_bot_id,
      :entity_type,
      :entity_id,
      execution_config: {}
    )
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_tasks(tasks)
    filtrate(tasks)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def render_validation_errors(errors)
    render json: {
      message: 'Validation failed',
      errors: errors.full_messages,
      details: errors.messages
    }, status: :unprocessable_entity
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
