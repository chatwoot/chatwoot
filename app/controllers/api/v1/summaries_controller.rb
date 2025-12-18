class Api::V1::SummariesController < Api::BaseController
  before_action :set_conversation

  def show
    force_refresh = params[:force_refresh] == 'true'

    service = Conversations::SummaryService.new(
      conversation: @conversation,
      force_refresh: force_refresh
    )

    result = service.perform

    if result[:success]
      render json: result[:data]
    else
      render json: { error: result[:error] }, status: result[:status]
    end
  end

  private

  def set_conversation
    conversation_id = params[:conversation_id]

    unless conversation_id.present?
      render json: { error: 'conversation_id is required' }, status: :bad_request
      return
    end

    @conversation = Conversation.find_by!(display_id: conversation_id)

    return if Current.user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
