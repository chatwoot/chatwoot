class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    @conversation ||= find_conversation
    authorize @conversation.inbox, :show? unless member_of_conversation_team?
  end

  def find_conversation
    Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def member_of_conversation_team?
    @conversation.team&.team_members&.exists?(user_id: Current.user.id)
  end
end
