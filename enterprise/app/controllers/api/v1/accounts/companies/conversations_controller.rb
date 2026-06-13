class Api::V1::Accounts::Companies::ConversationsController < Api::V1::Accounts::Companies::BaseController
  before_action :authorize_company_read!

  def index
    conversations = Current.account.conversations.includes(
      :assignee, :contact, :inbox, :taggings
    ).where(contact_id: @company.contacts.select(:id))

    @conversations = Conversations::PermissionFilterService.new(
      conversations,
      Current.user,
      Current.account
    ).perform.order(last_activity_at: :desc).limit(20)
  end
end
