class Api::V1::Accounts::Captain::CopilotThreadsController < Api::V1::Accounts::BaseController
  include Captain::Copilot::ConversationAccess

  before_action :ensure_message, only: :create
  before_action :ensure_accessible_conversation, only: :create

  def index
    @copilot_threads = Current.account.copilot_threads
                              .where(user_id: Current.user.id)
                              .includes(:user, :assistant)
                              .order(created_at: :desc, id: :desc)
                              .page(permitted_params[:page] || 1)
                              .per(5)
  end

  def create # rubocop:disable Metrics/MethodLength
    ActiveRecord::Base.transaction do
      @copilot_thread = Current.account.copilot_threads.create!(
        title: copilot_thread_params[:message].truncate(ApplicationRecord::MAX_STRING_COLUMN_LENGTH, omission: ''),
        user: Current.user,
        assistant: assistant,
        engine: engine
      )

      copilot_message = @copilot_thread.copilot_messages.create!(
        message_type: :user,
        message: { content: copilot_thread_params[:message] }
      )

      if @copilot_thread.v2?
        @copilot_run = Copilot::V2::RunService.new(thread: @copilot_thread, user: Current.user).start(message: copilot_message, enqueue: false)
      else
        build_copilot_response(copilot_message)
      end
    end
    Copilot::V2::RunJob.perform_later(@copilot_run.id) if @copilot_run
  rescue Copilot::V2::RunService::Unavailable => e
    render json: { error: 'execution_unavailable', message: e.message }, status: :forbidden
  end

  private

  def build_copilot_response(copilot_message)
    if Current.account.usage_limits[:captain][:responses][:current_available].positive?
      enqueue_copilot_response(copilot_message)
    else
      copilot_message.copilot_thread.copilot_messages.create!(
        message_type: :assistant,
        message: { content: I18n.t('captain.copilot_limit') }
      )
    end
  end

  def enqueue_copilot_response(copilot_message)
    return enqueue_reply_suggestion if reply_suggestion?

    copilot_message.enqueue_response_job(copilot_thread_params[:conversation_id], Current.user.id)
  end

  def enqueue_reply_suggestion
    Captain::Copilot::ReplySuggestionJob.perform_later(
      assistant: @copilot_thread.assistant,
      conversation_id: copilot_thread_params[:conversation_id],
      user_id: Current.user.id,
      copilot_thread_id: @copilot_thread.id
    )
  end

  def ensure_message
    if engine == 'v2' && !params[:message].is_a?(String)
      return render json: { error: 'message must be a non-empty string' }, status: :unprocessable_entity
    end

    return render_could_not_create_error(I18n.t('captain.copilot_message_required')) if copilot_thread_params[:message].blank?
  end

  def ensure_accessible_conversation
    return unless reply_suggestion?

    conversation = accessible_conversation(
      account: Current.account,
      user: Current.user,
      display_id: copilot_thread_params[:conversation_id]
    )
    raise ActiveRecord::RecordNotFound, 'Conversation not found' if conversation.blank?
  end

  def reply_suggestion?
    copilot_thread_params[:request_type] == 'reply_suggestion'
  end

  def assistant
    return if engine == 'v2' && copilot_thread_params[:assistant_id].blank?

    Current.account.captain_assistants.find(copilot_thread_params[:assistant_id])
  end

  def engine
    chat_request = copilot_thread_params[:request_type].blank? || copilot_thread_params[:request_type] == 'chat'
    chat_request && Current.account.feature_enabled?('copilot_v2') ? 'v2' : 'legacy'
  end

  def copilot_thread_params
    params.permit(:message, :assistant_id, :conversation_id, :request_type)
  end

  def permitted_params
    params.permit(:page)
  end
end
