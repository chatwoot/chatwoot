class Api::V1::Accounts::Contacts::ConversationsController < Api::V1::Accounts::Contacts::BaseController
  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
  end

  private

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(
      Current.user,
      conversation_finder_params
    )
  end

  def conversation_finder_params
    # Permit both scalar and array status values for flexibility
    # Default to 'all' status for contact conversations (returns all statuses,
    # matching the original behavior before this refactor)
    permitted = params.permit(:status, status: [])
    status_value = permitted[:status].presence || 'all'

    {
      contact_id: @contact.id,
      status: status_value
    }
  end
end
