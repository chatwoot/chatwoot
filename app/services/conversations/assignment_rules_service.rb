# Enforces manual assignment rules for agents:
# - an agent can't hold more open conversations than their account user's max_open_conversations
class Conversations::AssignmentRulesService
  def initialize(account:, assignee:, conversations:)
    @account = account
    @assignee = assignee
    @conversations = conversations.to_a
  end

  def validate!
    limit = account.account_users.find_by!(user_id: assignee.id).max_open_conversations
    return if limit.blank?
    return if incoming_count.zero?
    return if account.conversations.open.where(assignee_id: assignee.id).count + incoming_count <= limit

    raise CustomExceptions::ConversationAssignmentNotAllowed,
          { message: I18n.t('errors.conversations.assignment.limit_reached', agent_name: assignee.available_name, limit: limit) }
  end

  private

  attr_reader :account, :assignee, :conversations

  def incoming_count
    @incoming_count ||= conversations.count { |conversation| conversation.assignee_id != assignee.id && conversation.open? }
  end
end
