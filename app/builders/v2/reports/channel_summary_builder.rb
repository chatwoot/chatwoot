class V2::Reports::ChannelSummaryBuilder
  include DateRangeHelper

  MAX_DURATION = 6.months

  pattr_initialize [:account!, :params!]

  def build
    raise CustomExceptions::Report::InvalidDateRange, {} if date_range_exceeds_limit?

    conversations_by_channel_and_status.transform_values { |status_counts| build_channel_stats(status_counts) }
  end

  private

  def date_range_exceeds_limit?
    return false if range.nil?

    (range.end.to_date - range.begin.to_date).days > MAX_DURATION
  end

  def conversations_by_channel_and_status
    account.conversations
           .joins(:inbox)
           .where(created_at: range)
           .group('inboxes.channel_type', 'conversations.status')
           .count
           .each_with_object({}) do |((channel_type, status), count), grouped|
      grouped[channel_type] ||= {}
      grouped[channel_type][status] = count
    end
  end

  def build_channel_stats(status_counts)
    open_count = status_counts['open'] || 0
    resolved_count = status_counts['resolved'] || 0
    pending_count = status_counts['pending'] || 0
    snoozed_count = status_counts['snoozed'] || 0

    {
      open: open_count,
      resolved: resolved_count,
      pending: pending_count,
      snoozed: snoozed_count,
      total: open_count + resolved_count + pending_count + snoozed_count
    }
  end
end
