# Builds a time series for Captain involvement and autonomous resolution.
# Current and comparison buckets are computed in one outcome-table scan and
# follow the viewer's calendar timezone.
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
    comparison_buckets = previous_period_buckets(buckets)
    counts = bucket_counts(buckets + comparison_buckets)
    current_counts = counts.first(buckets.length)
    previous_counts = counts.last(buckets.length)

    {
      granularity: granularity,
      buckets: buckets.each_with_index.map do |bucket, index|
        serialize_bucket(bucket, current_counts[index], previous_counts[index])
      end
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
        final: final_bucket,
        exclude_end: false
      }
      starts_at = next_starts_at
    end

    buckets
  end

  # Align comparison buckets by elapsed position while retaining the current
  # period's bucket count. The final bucket absorbs trailing comparison days.
  def previous_period_buckets(buckets)
    period_offset = window.previous.first - window.current.first
    exclude_end = window.previous.last == window.current.first

    buckets.map do |bucket|
      starts_at = bucket[:starts_at] + period_offset
      ends_at = comparison_bucket_end(bucket, period_offset)

      {
        starts_at: starts_at,
        ends_at: ends_at,
        final: ends_at >= window.previous.last,
        exclude_end: exclude_end
      }
    end
  end

  def comparison_bucket_end(bucket, period_offset)
    return window.previous.last if bucket[:final]

    [bucket[:ends_at] + period_offset, window.previous.last].min
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

  def serialize_bucket(bucket, current_counts, previous_counts)
    {
      starts_on: bucket[:starts_at].to_date,
      ends_on: bucket[:ends_on],
      conversations_handled: current_counts[0],
      resolved_by_captain: current_counts[1],
      current_resolution_rate: resolution_rate(current_counts),
      previous_resolution_rate: resolution_rate(previous_counts)
    }
  end

  def bucket_predicate(bucket)
    starts_in_bucket = outcomes_table[:started_at].gteq(bucket[:starts_at])
    ends_in_bucket = if bucket[:final] && !bucket[:exclude_end]
                       outcomes_table[:started_at].lteq(bucket[:ends_at])
                     else
                       outcomes_table[:started_at].lt(bucket[:ends_at])
                     end

    starts_in_bucket.and(ends_in_bucket)
  end

  def outcomes_scope
    account.conversation_outcomes.where(
      assistant_id: assistant.id,
      started_at: window.previous.first..window.current.last
    )
  end

  def filtered_count(predicate)
    Arel.star.count.filter(predicate)
  end

  def outcomes_table
    @outcomes_table ||= ConversationOutcome.arel_table
  end

  def resolution_rate(counts)
    handled, resolved = counts
    return if handled.zero?

    (resolved.to_f / handled * 100).round(1)
  end
end
