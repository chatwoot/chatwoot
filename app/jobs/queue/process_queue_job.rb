class Queue::ProcessQueueJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    Rails.logger.info "[QUEUE][JOB] Start for account=#{account_id}"

    account = find_active_account(account_id)
    unless account
      Rails.logger.info "[QUEUE][JOB] Stop: account not found or queue disabled"
      return
    end

    queue_service = ChatQueue::QueueService.new(account: account)
    size = queue_service.queue_size
    Rails.logger.info "[QUEUE][JOB] Current queue_size=#{size} for account=#{account.id}"
    return if size.zero?

    conv = ConversationQueue
             .where(account_id: account.id, status: :waiting)
             .order(:position, :queued_at)
             .limit(1)
             .first

    unless conv
      Rails.logger.info "[QUEUE][JOB] No waiting conversations found"
      return
    end

    Rails.logger.info "[QUEUE][JOB] Picked conversation_queue_id=#{conv.id} conv_id=#{conv.conversation_id} position=#{conv.position}"

    agent_ids_sorted = queue_service.online_agents_list
    Rails.logger.info "[QUEUE][JOB] Online agents sorted: #{agent_ids_sorted.inspect}"

    if agent_ids_sorted.empty?
      Rails.logger.info "[QUEUE][JOB] No agents available online"
      return
    end

    agents = User.where(id: agent_ids_sorted).index_by(&:id)
    Rails.logger.info "[QUEUE][JOB] Loaded agents: #{agents.keys.inspect}"

    assigned = false
    agent_ids_sorted.each do |agent_id|
      agent = agents[agent_id]
      unless agent
        Rails.logger.info "[QUEUE][JOB] Agent #{agent_id} is missing, skipping"
        next
      end

      Rails.logger.info "[QUEUE][JOB] Trying to assign conv_id=#{conv.conversation_id} to agent_id=#{agent.id}"

      if queue_service.assign_specific_from_queue!(agent, conv.conversation_id)
        Rails.logger.info "[QUEUE][JOB] SUCCESS assigned conv_id=#{conv.conversation_id} to agent_id=#{agent.id}"
        assigned = true
        break
      else
        Rails.logger.info "[QUEUE][JOB] FAIL assign to agent_id=#{agent.id}, trying next"
      end
    end

    unless assigned
      Rails.logger.info "[QUEUE][JOB] Could not assign conv_id=#{conv.conversation_id} to any agent"
      return
    end

    if queue_service.queue_size.positive?
      Rails.logger.info "[QUEUE][JOB] Queue still has items, scheduling next run"
      Queue::ProcessQueueJob.set(wait: 1.second).perform_later(account_id)
    else
      Rails.logger.info "[QUEUE][JOB] Queue empty after assign, stopping"
    end
  end

  private

  def find_active_account(account_id)
    account = Account.find_by(id: account_id)
    return nil unless account&.queue_enabled?
    account
  end
end
