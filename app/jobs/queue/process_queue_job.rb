class Queue::ProcessQueueJob < ApplicationJob
  queue_as :default

  LOCK_TTL = 3

  def perform(account_id)
    return unless lock!(account_id)

    account = find_active_account(account_id)
    return unless account

    queue_service = ChatQueue::QueueService.new(account: account)
    return if queue_service.queue_size.zero?

    conv = ConversationQueue
             .where(account_id: account.id, status: :waiting)
             .order(:position, :queued_at)
             .limit(1)
             .first

    return unless conv

    agent_ids_sorted = queue_service.online_agents_list
    return if agent_ids_sorted.empty?

    agents = User.where(id: agent_ids_sorted).index_by(&:id)

    assigned = false
    agent_ids_sorted.each do |agent_id|
      agent = agents[agent_id]
      next unless agent

      if queue_service.assign_specific_from_queue!(agent, conv.conversation_id)
        assigned = true
        break
      end
    end

    if assigned && queue_service.queue_size.positive?
      Queue::ProcessQueueJob.set(wait: 1.second).perform_later(account_id)
    end

  ensure
    unlock!(account_id)
  end

  private

  def lock!(account_id)
    key = lock_key(account_id)
    result = redis.set(key, "1", nx: true, ex: LOCK_TTL)
    !!result
  end

  def unlock!(account_id)
    redis.del(lock_key(account_id))
  end

  def lock_key(account_id)
    "queue:process_lock:account:#{account_id}"
  end

  def redis
    @redis ||= Redis.new(url: ENV["REDIS_URL"])
  end

  def find_active_account(account_id)
    account = Account.find_by(id: account_id)
    return nil unless account&.queue_enabled?
    account
  end
end
