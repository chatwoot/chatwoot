class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_role == 'administrator'

    accessible_conversations
  end

  private

  def accessible_conversations
    inbox_scoped = conversations.where(inbox: user.inboxes.where(account_id: account.id))

    # Within the inboxes the agent can access, hide conversations that belong to a
    # team the agent isn't a member of. Conversations with no team yet (pending triage)
    # remain visible to everyone with inbox access.
    inbox_scoped.where(team_id: nil).or(inbox_scoped.where(team: user_teams))
  end

  def user_teams
    user.teams.where(account_id: account.id)
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
