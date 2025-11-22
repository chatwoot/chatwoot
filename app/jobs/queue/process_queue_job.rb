class Queue::ProcessQueueJob < ApplicationJob
  queue_as :default

  MAX_QUEUE_CHECK = 200

  def perform(account_id)
    account = find_active_account(account_id)
    return unless account

    queue_service = ChatQueue::QueueService.new(account: account)
    return if queue_service.queue_size.zero?

    assign_conversations(account, queue_service)
    if queue_service.queue_size > 0
      Queue::ProcessQueueJob.set(wait: 1.second).perform_later(account_id)
    end
  end

  private

  def find_active_account(account_id)
    account = Account.find_by(id: account_id)
    return nil unless account&.queue_enabled?
    account
  end

  def assign_conversations(account, queue_service)
    online_agents = get_available_agents(account)
    return if online_agents.empty?
  
    queue_ids = fetch_queue_ids_sql(account)
    return if queue_ids.empty?
  
    queue_ids.each do |conv_id|
      assigned = false

      online_agents.each do |agent|
        if queue_service.assign_specific_from_queue!(agent, conv_id)
          assigned = true
          break
        end
      end

      break unless assigned
    end
  end

  def fetch_queue_ids_sql(account)
    ConversationQueue
      .where(account_id: account.id, status: :waiting)
      .order(:position, :queued_at)
      .limit(MAX_QUEUE_CHECK)
      .pluck(:conversation_id)
  end

  def get_available_agents(account)
    statuses = OnlineStatusTracker.get_available_users(account.id) || {}

    online_ids =
      statuses.select { |_id, status| status == 'online' }
              .keys
              .map(&:to_i)

    return [] if online_ids.empty?

    User.where(id: online_ids)
  end
end
