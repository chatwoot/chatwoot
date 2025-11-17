class Queue::ProcessQueueJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account = find_active_account(account_id)
    return unless account

    queue_service = Queue::QueueService.new(account: account)
    return if queue_empty?(queue_service)

    assign_conversations(account, queue_service)
  end

  private

  def find_active_account(account_id)
    account = Account.find_by(id: account_id)
    return nil unless account&.queue_enabled?

    account
  end

  def queue_empty?(queue_service)
    queue_service.queue_size.zero?
  end

  def assign_conversations(account, queue_service)
    online_agents = get_available_agents(account)
    return if online_agents.empty?

    online_agents.each do |agent|
      next unless agent_has_capacity?(account, agent)

      conversation = queue_service.assign_from_queue(agent)
      break if conversation
    end
  end

  def get_available_agents(account)
    online_users = OnlineStatusTracker.get_available_users(account.id) || {}
    online_user_ids = online_users.select { |_id, status| status == 'online' }.keys.map(&:to_i)
    return [] if online_user_ids.empty?

    AccountUser
      .where(account_id: account.id, user_id: online_user_ids)
      .where(availability: :online)
      .includes(:user)
      .map(&:user)
  end

  def agent_has_capacity?(account, agent)
    active_count = Conversation
                   .where(assignee_id: agent.id, account_id: account.id)
                   .where.not(status: :resolved)
                   .count

    account_user = AccountUser.find_by(account_id: account.id, user_id: agent.id)
    limit = if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
              account_user.active_chat_limit.to_i
            elsif account.active_chat_limit_enabled? && account.active_chat_limit.present?
              account.active_chat_limit_value.to_i
            end

    limit.nil? || active_count < limit
  end
end
