class Api::V1::Accounts::Contacts::ConversationsController < Api::V1::Accounts::Contacts::BaseController
  def index
    conversations = Current.account.conversations.includes(
      :assignee, :contact, :inbox, :taggings
    ).where(contact_id: @contact.id)

    conversations = Conversations::PermissionFilterService.new(
      conversations,
      Current.user,
      Current.account
    ).perform

    # Newest-created first keeps the window contiguous even when the limit truncates it.
    @conversations = conversations.order(created_at: :desc, id: :desc).limit(20)
  end
end
