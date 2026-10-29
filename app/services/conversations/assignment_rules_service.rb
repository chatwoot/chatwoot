# Enforces the account user's max_open_conversations on manual assignments by humans.
# Auto assignment and reopenings triggered by contact messages don't go through it.
class Conversations::AssignmentRulesService
  def initialize(account:, assignee:)
    @account = account
    @assignee = assignee
  end

  # Runs the writes in the block in a transaction and rolls them back if they leave the assignee over the limit.
  # Locking the account user serializes concurrent assignments to the same agent.
  def enforce!
    ActiveRecord::Base.transaction do
      next yield if limit.blank?

      account_user.lock!
      open_before = open_count
      result = yield
      open_after = open_count
      raise_limit_reached if open_after > account_user.max_open_conversations && open_after > open_before
      result
    end
  end

  # For writes that happen later in a job (bulk actions): checks the conversations that would become open assignments.
  def validate!(conversations, status: nil)
    return if limit.blank?

    incoming = conversations.count { |conversation| conversation.assignee_id != assignee.id && (status || conversation.status).to_s == 'open' }
    raise_limit_reached if incoming.positive? && open_count + incoming > limit
  end

  private

  attr_reader :account, :assignee

  def account_user
    @account_user ||= account.account_users.find_by!(user_id: assignee.id)
  end

  def limit
    return if assignee.blank?

    account_user.max_open_conversations
  end

  def open_count
    account.conversations.open.where(assignee_id: assignee.id).count
  end

  def raise_limit_reached
    message = I18n.t('errors.conversations.assignment.limit_reached', agent_name: assignee.available_name, limit: account_user.max_open_conversations)
    raise CustomExceptions::ConversationAssignmentNotAllowed, { message: message }
  end
end
