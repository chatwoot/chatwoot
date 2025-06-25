class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    # The base implementation simply returns all conversations
    # Enterprise edition extends this with permission-based filtering
    conversations
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
