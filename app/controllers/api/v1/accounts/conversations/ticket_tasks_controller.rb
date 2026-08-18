class Api::V1::Accounts::Conversations::TicketTasksController < Api::V1::Accounts::Conversations::BaseController
  before_action :fetch_ticket
  before_action :fetch_task, only: [:update, :destroy]

  def create
    @task = @ticket.ticket_tasks.create!(
      task_params.merge(account_id: @ticket.account_id, created_by_id: Current.user.is_a?(User) ? Current.user.id : nil)
    )
    render action: 'show'
  end

  def update
    @task.update!(task_params)
    render action: 'show'
  end

  def destroy
    @task.destroy!
    head :ok
  end

  private

  def fetch_ticket
    @ticket = @conversation.ticket
    head :not_found if @ticket.blank?
  end

  def fetch_task
    @task = @ticket.ticket_tasks.find(params[:id])
  end

  def task_params
    params.permit(:title, :description, :status, :assignee_id, :team_id, :due_at)
  end
end
