class Api::V1::Accounts::MessageStatusController < Api::V1::Accounts::BaseController
  def status
    message_ids = permitted_params[:ids] || []

    if message_ids.empty?
      render json: { error: 'ids parameter is required' }, status: :bad_request
      return
    end

    # Filter messages to only include those from inboxes the user has access to
    accessible_inbox_ids = accessible_inbox_ids_for_user
    @messages = Current.account.messages.where(id: message_ids, inbox_id: accessible_inbox_ids)

    render json: { messages: @messages.map { |msg| { ID: msg.id, Status: msg.status } } }
  end

  private

  def permitted_params
    params.permit(ids: [])
  end

  def accessible_inbox_ids_for_user
    # Administrators with access to all inboxes can see all messages
    return Current.account.inboxes.pluck(:id) if should_skip_inbox_filtering?

    # Regular agents can only see messages from their assigned inboxes
    Current.user.assigned_inboxes.where(account_id: Current.account.id).pluck(:id)
  end

  def should_skip_inbox_filtering?
    Current.account_user&.administrator? || user_has_access_to_all_inboxes?
  end

  def user_has_access_to_all_inboxes?
    accessible_ids = Current.user.assigned_inboxes.where(account_id: Current.account.id).pluck(:id)
    accessible_ids.sort == Current.account.inboxes.pluck(:id).sort
  end
end

