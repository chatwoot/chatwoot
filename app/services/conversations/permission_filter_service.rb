class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_role == 'administrator'

    apply_conversation_filters
  end

  private

  def apply_conversation_filters
    base_conversations = accessible_conversations

    case account_user&.conversation_filter_mode
    when 'team_conversations_only'
      filter_by_team(base_conversations)
    when 'assigned_conversations_only'
      filter_by_assigned(base_conversations)
    when 'unassigned_conversations_only'
      filter_by_unassigned(base_conversations)
    when 'team_unassigned_or_mine'
      filter_by_team_unassigned_or_mine(base_conversations)
    else
      base_conversations
    end
  end

  def accessible_conversations
    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  def filter_by_team(base_conversations)
    team_ids = user.teams.where(account_id: account.id).pluck(:id)
    return base_conversations.none if team_ids.empty?

    base_conversations.where(team_id: team_ids)
  end

  def filter_by_assigned(base_conversations)
    base_conversations.where(assignee_id: user.id)
  end

  def filter_by_unassigned(base_conversations)
    base_conversations.where(assignee_id: nil)
  end

  def filter_by_team_unassigned_or_mine(base_conversations)
    team_ids = user.teams.where(account_id: account.id).pluck(:id)
    return base_conversations.none if team_ids.empty?

    # Conversas do time que estão sem agente OU atribuídas ao usuário atual
    base_conversations.where(team_id: team_ids)
                      .where('assignee_id IS NULL OR assignee_id = ?', user.id)
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
