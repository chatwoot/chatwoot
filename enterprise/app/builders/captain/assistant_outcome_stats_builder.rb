# Computes per-assistant outcome metrics for the Captain value report from
# captain_conversation_outcomes. The cohort for a window is the demand that
# entered it (rows created inside the window), so every rate shares one
# denominator and a conversation never migrates between windows as it
# progresses.
#
# The table stores only facts (see Captain::ConversationOutcome); every
# classification here is a query-time expression, computed for the current and
# previous window in a single scan via conditional FILTER aggregation.
class Captain::AssistantOutcomeStatsBuilder
  # How long an autonomous resolution must stay closed to count as durable.
  # Resolutions younger than this are excluded from the durability denominator
  # rather than counted as durable-so-far.
  DURABLE_RESOLUTION_WINDOW = 7.days

  # Captain participated: replied publicly, or handed off for a real reason.
  # A usage-limit handoff is blocked demand, not participation.
  INVOLVED_SQL = "(first_captain_reply_at IS NOT NULL OR (handoff_at IS NOT NULL AND handoff_reason_category != 'usage_limit'))".freeze

  # Resolved by Captain alone: no handoff and no public human reply before the
  # resolution that stuck.
  AUTONOMOUS_SQL = '(resolved_at IS NOT NULL AND first_captain_reply_at IS NOT NULL AND handoff_at IS NULL ' \
                   'AND (first_human_reply_at IS NULL OR first_human_reply_at > resolved_at))'.freeze

  # Resolved with Captain participation but a human in the loop.
  ASSISTED_SQL = "(resolved_at IS NOT NULL AND #{INVOLVED_SQL} AND NOT #{AUTONOMOUS_SQL})".freeze

  # The tracker only records reopens that happen after the current resolution,
  # so a reopen timestamp at or before resolved_at belongs to an earlier,
  # superseded resolution.
  NOT_REOPENED_SQL = '(last_reopened_at IS NULL OR last_reopened_at <= resolved_at)'.freeze

  attr_reader :assistant, :account

  delegate :range, :period, to: :window

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  # Metric key => [window_metrics key, trend mode].
  PACKED_METRICS = {
    eligible_conversations: %i[eligible percent],
    coverage_rate: %i[coverage point],
    autonomous_resolutions: %i[autonomous percent],
    autonomous_resolution_rate: %i[autonomous_rate point],
    assisted_resolutions: %i[assisted percent],
    durable_resolution_rate: %i[durable_rate point],
    csat_score: %i[csat absolute],
    median_first_response_seconds: %i[median_first_response absolute],
    median_resolution_seconds: %i[median_resolution absolute]
  }.freeze

  def metrics
    rows = window_rows
    current = window_metrics(rows[:current])
    previous = window_metrics(rows[:previous])

    packed = PACKED_METRICS.transform_values { |(key, mode)| pack(current[key], previous[key], mode) }
    packed.merge(
      human_only_csat_score: pack(human_only_csat(window.current), human_only_csat(window.previous), :absolute),
      handoff_reasons: handoff_reasons
    )
  end

  private

  attr_reader :window

  def window_metrics(row)
    eligible, involved, autonomous, assisted, assessable, durable, csat, first_response, resolution = row

    {
      eligible: eligible,
      coverage: rate(involved, eligible),
      autonomous: autonomous,
      autonomous_rate: rate(autonomous, eligible),
      assisted: assisted,
      durable_rate: rate(durable, assessable),
      csat: csat&.to_f&.round(2) || 0,
      median_first_response: first_response.to_i,
      median_resolution: resolution.to_i
    }
  end

  # One scan over the full span computes all aggregates for both windows.
  def window_rows
    per_window = window_aggregates(window_clause(window.current)) + window_aggregates(window_clause(window.previous))
    row = outcomes_scope(full_span).reorder(nil).pick(*per_window.map { |sql| Arel.sql(sql) })

    { current: row[0..8], previous: row[9..17] }
  end

  def window_aggregates(clause)
    assessable = "#{AUTONOMOUS_SQL} AND resolved_at <= #{quote(durable_cutoff)}"

    [
      "COUNT(*) FILTER (WHERE #{clause})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{INVOLVED_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{AUTONOMOUS_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{ASSISTED_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{assessable})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{assessable} AND #{NOT_REOPENED_SQL})",
      "AVG(csat_rating) FILTER (WHERE #{clause} AND #{INVOLVED_SQL} AND csat_rating IS NOT NULL)",
      'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (first_captain_reply_at - created_at))) ' \
      "FILTER (WHERE #{clause} AND first_captain_reply_at IS NOT NULL)",
      'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (resolved_at - created_at))) ' \
      "FILTER (WHERE #{clause} AND #{INVOLVED_SQL} AND resolved_at IS NOT NULL)"
    ]
  end

  def handoff_reasons
    outcomes_scope(window.current).where.not(handoff_reason_category: nil).group(:handoff_reason_category).count
  end

  # CSAT for conversations no Captain assistant participated in, as the
  # baseline the Captain CSAT is compared against.
  def human_only_csat(range)
    involved_conversations = Captain::ConversationOutcome
                             .where(account_id: account.id)
                             .where(INVOLVED_SQL)
                             .select(:conversation_id)
    score = account.csat_survey_responses
                   .where(created_at: range)
                   .where.not(conversation_id: involved_conversations)
                   .average(:rating)
    score&.to_f&.round(2) || 0
  end

  def outcomes_scope(range)
    assistant.conversation_outcomes.where(created_at: range)
  end

  def full_span
    [window.current.first, window.previous.first].min..window.current.last
  end

  def durable_cutoff
    @durable_cutoff ||= Time.current - DURABLE_RESOLUTION_WINDOW
  end

  def window_clause(range)
    "created_at >= #{quote(range.first)} AND created_at <= #{quote(range.last)}"
  end

  def quote(value)
    account.class.connection.quote(value)
  end

  def rate(numerator, denominator)
    return 0 if denominator.zero?

    (numerator.to_f / denominator * 100).round(1)
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
