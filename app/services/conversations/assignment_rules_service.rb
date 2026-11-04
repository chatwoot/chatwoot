# Enforces the account user's max_open_conversations on manual assignments by humans.
# Auto assignment and reopenings triggered by contact messages don't go through it.
class Conversations::AssignmentRulesService
  def initialize(account:, assignee:)
    @account = account
    @assignee = assignee
  end

  # Runs the writes in the block in a transaction and rolls them back if they leave the assignee over the limit.
  # Locking the account user before reading the limit serializes concurrent assignments and limit changes for the agent.
  def enforce!
    ActiveRecord::Base.transaction do
      next yield if assignee.blank?

      account_user.lock!
      next yield if account_user.max_open_conversations.blank?

      open_before = open_count
      result = yield
      open_after = open_count
      raise_limit_reached if open_after > account_user.max_open_conversations && open_after > open_before
      result
    end
  end

  # For writes that happen later in a job (bulk actions): checks the conversations that would become open assignments.
  def validate!(conversations, status: nil)
    return if assignee.blank? || account_user.max_open_conversations.blank?

    incoming = incoming_count(conversations, status)
    raise_limit_reached if incoming.positive? && open_count + incoming > account_user.max_open_conversations
  end

  private

  attr_reader :account, :assignee

  def account_user
    @account_user ||= account.account_users.find_by!(user_id: assignee.id)
  end

  # Conversations that end up open and aren't already part of open_count
  def incoming_count(conversations, status)
    conversations.count do |conversation|
      (status || conversation.status).to_s == 'open' && !(conversation.open? && conversation.assignee_id == assignee.id)
    end
  end

  def open_count
    account.conversations.open.where(assignee_id: assignee.id).count
  end

  def raise_limit_reached
    message = I18n.t('errors.conversations.assignment.limit_reached', agent_name: assignee.available_name, limit: account_user.max_open_conversations)
    raise CustomExceptions::ConversationAssignmentNotAllowed, { message: message }
  end
end
