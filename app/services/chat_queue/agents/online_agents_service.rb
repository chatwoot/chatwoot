class ChatQueue::Agents::OnlineAgentsService
  pattr_initialize [:account!]

  def list
    Rails.logger.info("[QUEUE][online] Fetching online agents for account #{account.id}")

    agent_ids = fetch_online_agent_ids
    Rails.logger.info("[QUEUE][online] Online IDs: #{agent_ids.inspect}")

    stats = build_agent_stats(agent_ids)
    sorted = sort_agents(stats)

    Rails.logger.info("[QUEUE][online] Sorted agent list: #{sorted.inspect}")
    sorted
  end

  private

  def fetch_online_agent_ids
    (OnlineStatusTracker.get_available_users(account.id) || {})
      .select { |_id, status| status == 'online' }
      .keys
      .map(&:to_i)
  end

  def build_agent_stats(agent_ids)
    agent_ids.map { |id| agent_stat_record(id) }
  end

  def agent_stat_record(id)
    active_count = Conversation
                   .where(account_id: account.id, assignee_id: id)
                   .where.not(status: :resolved)
                   .count

    last_closed = Conversation
                  .where(account_id: account.id, assignee_id: id, status: :resolved)
                  .order(updated_at: :desc)
                  .pick(:updated_at) || Time.zone.at(0)

    Rails.logger.info("[QUEUE][online] Agent #{id}: active=#{active_count}, last_closed=#{last_closed}")

    {
      id: id,
      active: active_count,
      last_closed: last_closed
    }
  end

  def sort_agents(stats)
    stats.sort_by { |a| [a[:active], a[:last_closed]] }.pluck(:id)
  end
end
