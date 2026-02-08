class V2::Reports::InboxSummaryBuilder < V2::Reports::BaseSummaryBuilder
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
    @resolved_count = fetch_resolved_count
    @avg_resolution_time = fetch_average_time('conversation_resolved')
    @avg_first_response_time = fetch_average_time('first_response')
    @avg_reply_time = fetch_average_time('reply_time')
  end

  def fetch_conversations_count
    account.conversations.where(created_at: range).group(group_by_key).count
  end

  def prepare_report
    account.inboxes.map do |inbox|
      build_inbox_stats(inbox)
    end
  end

  def build_inbox_stats(inbox)
    {
      id: inbox.id,
      conversations_count: conversations_count[inbox.id] || 0,
      resolved_conversations_count: resolved_count[inbox.id] || 0,
      avg_resolution_time: avg_resolution_time[inbox.id],
      avg_first_response_time: avg_first_response_time[inbox.id],
      avg_reply_time: avg_reply_time[inbox.id]
    }
  end

  def group_by_key
    :inbox_id
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]) ? :value_in_business_hours : :value
  end
end
