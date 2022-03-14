class Api::V1::Accounts::Conversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  before_action :current_account
  before_action :conversation

  private

  def conversation
    @conversation ||= Current.account.conversations.find_by(display_id: params[:conversation_id])
    authorize @conversation.inbox, :show?
  end
end
