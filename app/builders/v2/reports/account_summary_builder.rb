class V2::Reports::AccountSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time

  def load_data
    @conversations_count = fetch_conversations_count
    load_reporting_events_data
  end

  def fetch_conversations_count
    { account.id => account.conversations.where(created_at: range).count }
  end

  def prepare_report
    [{
      id: account.id,
      conversations_count: conversations_count[account.id] || 0,
      resolved_conversations_count: resolved_count[account.id] || 0,
      avg_resolution_time: avg_resolution_time[account.id],
      avg_first_response_time: avg_first_response_time[account.id],
      avg_reply_time: avg_reply_time[account.id]
    }]
  end

  def group_by_key
    :account_id
  end
end
