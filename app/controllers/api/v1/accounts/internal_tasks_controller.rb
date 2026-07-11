class Api::V1::Accounts::InternalTasksController < Api::V1::Accounts::BaseController
  rescue_from InternalTasks::AlreadyClaimedError, with: :render_already_claimed
  before_action :internal_task, except: [:index]

  def index
    authorize(InternalTask)
    @internal_tasks = filtered_tasks.includes(:created_by, :assigned_to, :team, :task_template,
                                              :source_message, :events, conversation: :contact)
                                    .order(created_at: :desc)
  end

  def show
    authorize @internal_task
  end

  def update
    authorize @internal_task
    @internal_task.update!(update_params)
    @internal_task.reload
    render :show
  end

  def destroy
    authorize @internal_task
    @internal_task.update!(status: 'cancelled', completed_at: Time.current)
    head :ok
  end

  def claim
    authorize @internal_task, :claim?
    @internal_task = InternalTasks::ClaimService.new(task: @internal_task, user: Current.user).perform
    render :show
  end

  def start
    authorize @internal_task, :start?
    @internal_task = InternalTasks::StartService.new(task: @internal_task, user: Current.user).perform
    render :show
  end

  def complete
    authorize @internal_task, :complete?
    @internal_task = InternalTasks::CompleteService.new(
      task: @internal_task,
      user: Current.user
    ).perform(
      metadata: params.fetch(:metadata, {}).to_unsafe_h,
      comment: params[:comment]
    )
    render :show
  end

  def comment
    authorize @internal_task, :update?
    InternalTaskEvent.record!(
      task: @internal_task,
      user: Current.user,
      event_type: 'comment',
      metadata: { comment: params.require(:comment) }
    )
    @internal_task.reload
    render :show
  end

  private

  def render_already_claimed(error)
    render json: {
      error: 'task_already_claimed',
      message: I18n.t('tasks.errors.already_claimed', default: 'Task already claimed by another user'),
      task_id: error.task.id
    }, status: :conflict
  end

  def internal_task
    @internal_task = policy_scope(InternalTask)
                       .includes(:created_by, :assigned_to, :team, :task_template,
                                 :source_message, { events: :user }, conversation: :contact)
                       .find(params[:id])
  end

  def filtered_tasks
    tasks = policy_scope(InternalTask)
    tasks = tasks.for_user(Current.user) if params[:assigned_to] == 'me'
    tasks = tasks.for_team(params[:team_id]) if params[:team_id].present?
    tasks = tasks.unclaimed if ActiveModel::Type::Boolean.new.cast(params[:unclaimed])
    tasks = tasks.where(status: status_filter) if status_filter.present?
    tasks = tasks.overdue if ActiveModel::Type::Boolean.new.cast(params[:overdue])
    tasks = tasks.where(conversation_id: conversation_id_filter) if conversation_id_filter.present?
    tasks
  end

  def status_filter
    return InternalTask::OPEN_STATUSES if params[:status].blank?

    params[:status].to_s.split(',')
  end

  def conversation_id_filter
    return if params[:conversation_id].blank?

    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    conversation.id
  end

  def update_params
    params.require(:internal_task).permit(
      :title, :description, :status, :priority, :assigned_to_id, :team_id, :due_at,
      metadata: {}
    )
  end
end
