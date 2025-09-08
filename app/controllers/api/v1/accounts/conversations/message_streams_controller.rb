class Api::V1::Accounts::Conversations::MessageStreamsController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  before_action :ensure_agent_bot!
  before_action :set_message, only: [:append, :finish]

  # POST /api/v1/accounts/:account_id/conversations/:conversation_id/message_streams/start
  # Params: { content: "", private: false, content_type: 'text', echo_id: 'optional', sender_id: bot_id }
  def start
    # indicate typing on
    toggle_typing('on')

    builder_params = {
      message_type: 'outgoing',
      # set a lightweight placeholder so UI renders a bubble; will be replaced on first append
      content: params[:content].presence || '…',
      private: ActiveModel::Type::Boolean.new.cast(params[:private]),
      content_type: params[:content_type] || 'text',
      sender_type: 'AgentBot',
      sender_id: Current.user.id,
      echo_id: params[:echo_id]
    };
    @message = Messages::MessageBuilder.new(Current.user, @conversation, builder_params).perform

    render 'api/v1/accounts/conversations/messages/create', status: :created
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  # POST /api/v1/accounts/:account_id/conversations/:conversation_id/message_streams/append
  # Params: { id: message_id, delta: "partial text" }
  def append
    delta = params[:delta].to_s
    return head :bad_request if delta.blank?

    current = @message.content.to_s
    new_content = if current == '…' || current.blank?
                    delta
                  else
                    current + delta
                  end

    @message.update!(content: new_content)
    # will emit MESSAGE_UPDATED via after_update_commit

    render 'api/v1/accounts/conversations/messages/update', status: :ok
  end

  # POST /api/v1/accounts/:account_id/conversations/:conversation_id/message_streams/finish
  # Params: { id: message_id, content: "final", status: 'sent'|'failed', external_error: '...' }
  def finish
    attrs = {}
    attrs[:content] = params[:content] if params.key?(:content)

    # optional status update similar to messages#update constraints
    if @conversation.inbox.api? && params[:status].present?
      Messages::StatusUpdateService.new(@message, params[:status], params[:external_error]).perform
      @message.reload
    end

    @message.update!(attrs) if attrs.present?

    # indicate typing off
    toggle_typing('off')

    render 'api/v1/accounts/conversations/messages/update', status: :ok
  end

  private

  def ensure_agent_bot!
    render_unauthorized('Only AgentBot can access streaming') unless Current.user.is_a?(AgentBot)
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
    render json: { error: 'Message must be outgoing and from this bot' }, status: :forbidden and return unless @message.outgoing?
    return if @message.sender == Current.user

    render json: { error: 'Not the sender of this message' }, status: :forbidden
  end

  def toggle_typing(status)
    typing_status_manager = ::Conversations::TypingStatusManager.new(@conversation, Current.user, { typing_status: status, is_private: false })
    typing_status_manager.toggle_typing_status
  end
end
