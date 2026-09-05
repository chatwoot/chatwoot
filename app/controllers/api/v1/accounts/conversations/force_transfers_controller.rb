class Api::V1::Accounts::Conversations::ForceTransfersController < Api::V1::Accounts::BaseController
  before_action :set_conversation

  def create
    authorize @conversation.inbox, :show?

    result = ChatQueue::ForceTransferService.new(
      conversation: @conversation,
      current_user: current_user
    ).perform

    if result[:success]
      render json: {
        success: true,
        agent: agent_payload(result[:agent]),
        message: result[:message]
      }, status: :ok
    else
      render json: {
        success: false,
        message: result[:message]
      }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
    render_not_found_error('Conversation') unless @conversation
  end

  def agent_payload(agent)
    return nil unless agent

    {
      id: agent.id,
      name: agent.name,
      email: agent.email,
      avatar_url: agent.avatar_url
    }
  end
end
