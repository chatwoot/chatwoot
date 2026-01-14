class V2::Reports::AgentSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time,
              :agent_chat_duration

  def load_data
    super
    @agent_chat_duration = fetch_agent_chat_duration
  end

  def fetch_conversations_count
    account.conversations.where(created_at: range).group('assignee_id').count
  end

  def fetch_agent_chat_duration
    account.reporting_events
           .where(name: :agent_chat_duration, created_at: range)
           .group(:user_id)
           .average(:value)
  end

  def prepare_report
    account.account_users.map do |account_user|
      build_agent_stats(account_user)
    end
  end

  def build_agent_stats(account_user)
    user_id = account_user.user_id
    {
      id: user_id,
      conversations_count: conversations_count[user_id] || 0,
      resolved_conversations_count: resolved_count[user_id] || 0,
      avg_resolution_time: avg_resolution_time[user_id],
      avg_first_response_time: avg_first_response_time[user_id],
      avg_reply_time: avg_reply_time[user_id],
      agent_chat_duration: (agent_chat_duration[user_id] || 0).to_i
    }
  end

  def group_by_key
    :user_id
  end
end
