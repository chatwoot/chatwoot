class V2::Reports::InboxSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count, :handled_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time

  def prepare_report
    reject_untouched_rows(
      account.inboxes.map { |inbox| build_inbox_stats(inbox) }
    )
  end

  def build_inbox_stats(inbox)
    {
      id: inbox.id,
      conversations_count: conversations_count[inbox.id] || 0,
      resolved_conversations_count: resolved_count[inbox.id] || 0,
      handled_conversations_count: handled_count[inbox.id] || 0,
      avg_resolution_time: avg_resolution_time[inbox.id],
      avg_first_response_time: avg_first_response_time[inbox.id],
      avg_reply_time: avg_reply_time[inbox.id]
    }
  end

  def group_by_key
    :inbox_id
  end
end
