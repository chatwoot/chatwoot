class Api::V1::Accounts::Captain::CopilotPendingAdminActionsController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator
  before_action :set_copilot_thread
  before_action :set_pending_action, only: [:confirm, :reject]

  def index
    @pending_actions = @copilot_thread.copilot_pending_admin_actions.pending.order(created_at: :desc)
  end

  def confirm
    result = Captain::Tools::Admin::Executor.execute!(
      pending_action: @pending_action,
      assistant: @copilot_thread.assistant,
      user: Current.user
    )
    @pending_action.update!(status: :confirmed)
    @copilot_message = @copilot_thread.copilot_messages.create!(
      message_type: :assistant,
      message: { content: result.to_s }
    )
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def reject
    @pending_action.update!(status: :rejected)
    head :ok
  end

  private

  def ensure_administrator
    render json: { error: 'Administrator access is required' }, status: :forbidden unless Current.account_user.administrator?
  end

  def set_copilot_thread
    @copilot_thread = Current.account.copilot_threads.find_by!(
      id: params[:copilot_thread_id],
      user: Current.user
    )
  end

  def set_pending_action
    @pending_action = @copilot_thread.copilot_pending_admin_actions.pending.find(params[:id])
  end
end
