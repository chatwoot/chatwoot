class Api::V1::Bot::ConversationsController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation

  # GET /api/v1/bot/conversations/:id
  # Lấy thông tin cuộc hội thoại với hiệu suất tối ưu
  def show
    @messages = @conversation.messages.includes(:attachments, :sender)
                             .where(private: false)
                             .order(created_at: :asc)
                             .last(100)

    render json: {
      id: @conversation.display_id,
      inbox_id: @conversation.inbox_id,
      status: @conversation.status,
      contact: @conversation.contact.as_json(only: [:id, :name, :email, :phone_number]),
      messages: @messages.as_json(include: [:attachments])
    }
  end

  # PATCH /api/v1/bot/conversations/:id
  # Cập nhật trạng thái cuộc hội thoại
  def update
    @conversation.update!(conversation_params)
    render json: @conversation
  end

  # POST /api/v1/bot/conversations/:id/typing_on
  # Bật typing indicator
  def typing_on
    result = Bot::TypingService.new(conversation: @conversation).enable_typing
    render json: { success: result }
  end

  # POST /api/v1/bot/conversations/:id/typing_off
  # Tắt typing indicator
  def typing_off
    result = Bot::TypingService.new(conversation: @conversation).disable_typing
    render json: { success: result }
  end

  # POST /api/v1/bot/conversations/:id/mark_seen
  # Đánh dấu tin nhắn đã xem
  def mark_seen
    result = Bot::TypingService.new(conversation: @conversation).mark_seen
    render json: { success: result }
  end

  private

  def fetch_conversation
    @conversation = Current.account.conversations.find_by(display_id: params[:id])
    render json: { error: 'Conversation not found' }, status: :not_found if @conversation.blank?
  end

  def conversation_params
    params.permit(:status, :priority, :assignee_id, :team_id)
  end
end
