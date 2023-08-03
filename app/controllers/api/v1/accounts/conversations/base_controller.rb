class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  # Spec verifying this is written in spec/controllers/api/v1/accounts/conversations/base_controller_spec.rb
  def conversation
    @conversation ||= find_conversation
    authorize @conversation, :show?
  end

  def find_conversation
    Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end
end
