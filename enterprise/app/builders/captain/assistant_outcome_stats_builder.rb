# Computes per-assistant outcome metrics for the Captain value report from
# captain_conversation_outcomes.
#
# Every metric is anchored on the timestamp of its own event (resolved_at,
# first_captain_reply_at, csat_received_at, handoff_at) rather than on when the
# conversation started. This keeps completed windows frozen (a late reopen or
# resolution never rewrites last month's numbers) and keeps the current window
# unbiased by conversations that simply haven't finished yet. Each anchor gets
# its own scan, bounded by the span covering both windows, computing current and
# previous via conditional FILTER aggregation.
class Captain::AssistantOutcomeStatsBuilder
  # How long an autonomous resolution must stay closed to count as durable.
  # Resolutions younger than this are excluded from the durability denominator
  # rather than counted as durable-so-far.
  DURABLE_RESOLUTION_WINDOW = 7.days

  # Classification predicates live on the model so every builder counts the
  # same rows (see Captain::ConversationOutcome).
  INVOLVED_SQL = Captain::ConversationOutcome::INVOLVED_SQL
  AUTONOMOUS_SQL = Captain::ConversationOutcome::AUTONOMOUS_SQL
  NOT_REOPENED_SQL = Captain::ConversationOutcome::NOT_REOPENED_SQL

  attr_reader :assistant, :account

  delegate :range, :period, to: :window

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def metrics
    resolution = resolution_rows

    {
      autonomous_resolutions: packed(resolution, :autonomous, :percent),
      durable_resolution_rate: packed(resolution, :durable_rate, :point),
      median_resolution_seconds: packed(resolution, :median, :absolute),
      median_first_response_seconds: packed_window(reply_rows, :absolute),
      csat_score: packed_window(csat_rows, :absolute),
      human_only_csat_score: packed_window(human_only_csat_rows, :absolute),
      handoff_reasons: handoff_reasons,
      flow: resolution_flow
    }
  end

  private

  attr_reader :window

  # Resolution-anchored aggregates: autonomous count, durability, and the
  # resolution-time median all describe resolutions that happened in the window.
  def resolution_rows
    per_window = [window.current, window.previous].flat_map { |range| resolution_aggregates(range) }
    row = outcomes.where(resolved_at: full_span).reorder(nil).pick(*per_window.map { |sql| Arel.sql(sql) })

    {
      current: unpack_resolution(row[0..3]),
      previous: unpack_resolution(row[4..7])
    }
  end

  def resolution_aggregates(range)
    resolved = between('resolved_at', range)
    assessable = "#{resolved} AND #{AUTONOMOUS_SQL} AND resolved_at <= #{quote(durable_cutoff)}"

    [
      "COUNT(*) FILTER (WHERE #{resolved} AND #{AUTONOMOUS_SQL})",
      "COUNT(*) FILTER (WHERE #{assessable})",
      "COUNT(*) FILTER (WHERE #{assessable} AND #{NOT_REOPENED_SQL})",
      'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (resolved_at - created_at))) ' \
      "FILTER (WHERE #{resolved} AND #{INVOLVED_SQL})"
    ]
  end

  def unpack_resolution(row)
    autonomous, assessable, durable, median = row

    { autonomous: autonomous, durable_rate: rate(durable, assessable), median: median.to_i }
  end

  # Median customer wait before Captain's first reply, for replies that
  # happened in the window.
  def reply_rows
    per_window = [window.current, window.previous].map do |range|
      'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (first_captain_reply_at - created_at))) ' \
        "FILTER (WHERE #{between('first_captain_reply_at', range)})"
    end
    row = outcomes.where(first_captain_reply_at: full_span).reorder(nil).pick(*per_window.map { |sql| Arel.sql(sql) })

    { current: row[0].to_i, previous: row[1].to_i }
  end

  # Average CSAT on involved conversations, anchored on when the rating landed.
  def csat_rows
    per_window = [window.current, window.previous].map do |range|
      "AVG(csat_rating) FILTER (WHERE #{between('csat_received_at', range)} AND #{INVOLVED_SQL})"
    end
    row = outcomes.where(csat_received_at: full_span).where.not(csat_rating: nil)
                  .reorder(nil).pick(*per_window.map { |sql| Arel.sql(sql) })

    { current: rounded_score(row[0]), previous: rounded_score(row[1]) }
  end

  def handoff_reasons
    outcomes.where(handoff_at: window.current).group(:handoff_reason_category).count
  end

  # Where every conversation Captain worked in the window stands right now, for
  # the resolution flow diagram. Unlike the event-anchored metrics this is a
  # cohort view — flows must conserve (each conversation exits exactly one
  # terminal), so conversations that haven't finished surface honestly as
  # still_open instead of distorting rates.
  def resolution_flow
    cohort = outcomes.where('first_captain_reply_at <= ? AND last_captain_reply_at >= ?', window.current.last, window.current.first)
    handled, autonomous, stayed_closed, handed, team_resolved = cohort.reorder(nil).pick(
      Arel.sql('COUNT(*)'),
      Arel.sql("COUNT(*) FILTER (WHERE #{AUTONOMOUS_SQL})"),
      Arel.sql("COUNT(*) FILTER (WHERE #{AUTONOMOUS_SQL} AND #{NOT_REOPENED_SQL})"),
      Arel.sql('COUNT(*) FILTER (WHERE handoff_at IS NOT NULL)'),
      Arel.sql("COUNT(*) FILTER (WHERE resolved_at IS NOT NULL AND handoff_at IS NULL AND NOT #{AUTONOMOUS_SQL})")
    )

    {
      handled: handled,
      captain_resolved: { total: autonomous, stayed_closed: stayed_closed, reopened: autonomous - stayed_closed },
      handed_to_team: { total: handed, reasons: cohort.where.not(handoff_at: nil).group(:handoff_reason_category).count },
      team_resolved: team_resolved,
      still_open: handled - autonomous - handed - team_resolved
    }
  end

  # CSAT for conversations no Captain assistant participated in, as the
  # baseline the Captain CSAT is compared against.
  def human_only_csat_rows
    { current: human_only_csat(window.current), previous: human_only_csat(window.previous) }
  end

  def human_only_csat(range)
    involved_conversations = Captain::ConversationOutcome
                             .where(account_id: account.id)
                             .where(INVOLVED_SQL)
                             .select(:conversation_id)
    score = account.csat_survey_responses
                   .where(created_at: range)
                   .where.not(conversation_id: involved_conversations)
                   .average(:rating)
    rounded_score(score)
  end

  def rounded_score(value)
    value&.to_f&.round(2) || 0
  end

  def outcomes
    assistant.conversation_outcomes
  end

  def full_span
    [window.current.first, window.previous.first].min..window.current.last
  end

  def durable_cutoff
    @durable_cutoff ||= Time.current - DURABLE_RESOLUTION_WINDOW
  end

  def between(column, range)
    "#{column} >= #{quote(range.first)} AND #{column} <= #{quote(range.last)}"
  end

  def quote(value)
    account.class.connection.quote(value)
  end

  def rate(numerator, denominator)
    return 0 if denominator.zero?

    (numerator.to_f / denominator * 100).round(1)
  end

  def packed(rows, key, mode)
    pack(rows[:current][key], rows[:previous][key], mode)
  end

  def packed_window(rows, mode)
    pack(rows[:current], rows[:previous], mode)
  end

  def pack(current, previous, mode)
    { current: current, previous: previous, trend: trend(current, previous, mode) }
  end

  def trend(current, previous, mode)
    case mode
    when :percent
      previous.zero? ? 0 : ((current - previous).to_f / previous * 100).round(1)
    else # :point and :absolute are both current - previous
      (current - previous).round(1)
    end
  end
end
