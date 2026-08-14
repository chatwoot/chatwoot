# Builds a time series for Captain involvement and autonomous resolution.
# All buckets are computed in one outcome-table scan and follow the viewer's
# calendar timezone while remaining clipped to the selected reporting window.
class Captain::AssistantResolutionTrendStatsBuilder
  include Captain::AssistantOutcomeClassification

  DAILY_GRANULARITY_THRESHOLD = 15.days
  WEEK_START = :sunday

  attr_reader :assistant, :account

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def metrics
    buckets = time_buckets
    counts = bucket_counts(buckets)

    {
      granularity: granularity,
      buckets: buckets.each_with_index.map { |bucket, index| serialize_bucket(bucket, counts[index]) }
    }
  end

  private

  attr_reader :window

  def time_buckets
    buckets = []
    starts_at = window.current.first

    while starts_at <= window.current.last
      next_starts_at = next_bucket_starts_at(starts_at)
      final_bucket = next_starts_at > window.current.last

      buckets << {
        starts_at: starts_at,
        ends_at: final_bucket ? window.current.last : next_starts_at,
        ends_on: final_bucket ? window.current.last.to_date : next_starts_at.to_date - 1.day,
        final: final_bucket
      }
      starts_at = next_starts_at
    end

    buckets
  end

  def granularity
    window.current.last - window.current.first <= DAILY_GRANULARITY_THRESHOLD ? :day : :week
  end

  def next_bucket_starts_at(starts_at)
    return starts_at.beginning_of_day + 1.day if granularity == :day

    starts_at.beginning_of_week(WEEK_START) + 1.week
  end

  def bucket_counts(buckets)
    aggregates = buckets.flat_map do |bucket|
      predicate = bucket_predicate(bucket)
      [
        filtered_count(predicate.and(involved(outcomes_table))),
        filtered_count(predicate.and(autonomous(outcomes_table)))
      ]
    end

    outcomes_scope.reorder(nil).pick(*aggregates).each_slice(2).to_a
  end

  def serialize_bucket(bucket, counts)
    {
      starts_on: bucket[:starts_at].to_date,
      ends_on: bucket[:ends_on],
      conversations_handled: counts[0],
      resolved_by_captain: counts[1]
    }
  end

  def bucket_predicate(bucket)
    starts_in_bucket = outcomes_table[:started_at].gteq(bucket[:starts_at])
    ends_in_bucket = if bucket[:final]
                       outcomes_table[:started_at].lteq(bucket[:ends_at])
                     else
                       outcomes_table[:started_at].lt(bucket[:ends_at])
                     end

    starts_in_bucket.and(ends_in_bucket)
  end

  def outcomes_scope
    account.conversation_outcomes.where(assistant_id: assistant.id, started_at: window.current)
  end

  def filtered_count(predicate)
    Arel.star.count.filter(predicate)
  end

  def outcomes_table
    @outcomes_table ||= ConversationOutcome.arel_table
  end
end
