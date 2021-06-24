class Api::V1::Accounts::Contacts::ConversationsController < Api::V1::Accounts::BaseController
  def index
    @conversations = Current.account.conversations.includes(
      :assignee, :contact, :inbox, :taggings
    ).where(inbox_id: inbox_ids, contact_id: permitted_params[:contact_id])
  end

  private

  def inbox_ids
    if Current.user.administrator? || Current.user.agent?
      Current.user.assigned_inboxes.pluck(:id)
    else
      []
    end
  end

  def permitted_params
    params.permit(:contact_id)
  end
end
