class Api::V1::Accounts::Contacts::ConversationsController < Api::V1::Accounts::Contacts::BaseController
  def index
    # Start with all conversations for this contact
    conversations = Current.account.conversations.includes(
      :assignee, :contact, :inbox, :taggings
    ).where(contact_id: @contact.id)

    # Apply permission-based filtering using the existing service
    conversations = Conversations::PermissionFilterService.new(
      conversations,
      Current.user,
      Current.account
    ).perform

    @conversations = conversations.order(last_activity_at: :desc).limit(20)
  end
end
