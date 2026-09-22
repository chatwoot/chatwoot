class Api::V1::Accounts::Captain::CopilotMessagesController < Api::V1::Accounts::BaseController
  before_action :set_copilot_thread

  def index
    @copilot_messages = @copilot_thread
                        .copilot_messages
                        .includes(:copilot_thread)
                        .order(created_at: :asc)
                        .page(permitted_params[:page] || 1)
                        .per(1000)
  end

  def create
    return create_v2_message if @copilot_thread.v2?

    @copilot_message = @copilot_thread.copilot_messages.create!(
      message: { content: params[:message] },
      message_type: :user
    )
    @copilot_message.enqueue_response_job(params[:conversation_id], Current.user.id)
  end

  private

  def create_v2_message
    unless params[:message].is_a?(String) && params[:message].present?
      return render json: { error: 'message must be a non-empty string' }, status: :unprocessable_entity
    end

    run = @copilot_thread.with_lock do
      @copilot_message = @copilot_thread.copilot_messages.create!(message: { content: params[:message] }, message_type: :user)
      Copilot::V2::RunService.new(thread: @copilot_thread, user: Current.user).start(message: @copilot_message, enqueue: false)
    end
    Copilot::V2::RunJob.perform_later(run.id)
  rescue Copilot::V2::RunService::ActiveRunConflict => e
    render json: { error: 'active_run_conflict', message: e.message }, status: :conflict
  rescue Copilot::V2::RunService::Unavailable => e
    render json: { error: 'execution_unavailable', message: e.message }, status: :forbidden
  end

  def set_copilot_thread
    @copilot_thread = Current.account.copilot_threads.find_by!(
      id: params[:copilot_thread_id],
      user: Current.user
    )
  end

  def permitted_params
    params.permit(:page)
  end
end
