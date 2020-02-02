class Api::V1::Contacts::ConversationsController < Api::BaseController
  def index
    @conversations = current_account.conversations.includes(
      :assignee, :contact, :inbox
    ).where(inbox_id: inbox_ids, contact_id: permitted_params[:contact_id])
  end

  private

  def inbox_ids
    if current_user.administrator?
      current_account.inboxes.pluck(:id)
    elsif current_user.agent?
      current_user.assigned_inboxes.pluck(:id)
    else
      []
    end
  end

  def permitted_params
    params.permit(:contact_id)
  end
end
