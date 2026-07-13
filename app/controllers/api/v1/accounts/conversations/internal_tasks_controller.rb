class Api::V1::Accounts::Conversations::InternalTasksController < Api::V1::Accounts::Conversations::BaseController
  def index
    authorize InternalTask
    @internal_tasks = policy_scope(InternalTask)
                        .where(conversation_id: @conversation.id)
                        .open
                        .includes(:created_by, :assigned_to, :team, :task_template, source_message: :attachments)
                        .order(created_at: :desc)
  end

  def create
    authorize InternalTask
    @internal_task = InternalTasks::CreateService.new(
      conversation: @conversation,
      user: Current.user,
      params: create_params
    ).perform
  end

  private

  def create_params
    params.require(:internal_task).permit(
      :task_template_id, :title, :description, :assigned_to_id, :team_id,
      :priority, :due_at, :depends_on_task_id, :source_message_id, metadata: {}
    ).to_h.symbolize_keys
  end
end
