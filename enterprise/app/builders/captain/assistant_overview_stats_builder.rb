# Computes the complete per-assistant metric set for the Captain overview.
# Funnel and outcome metrics use episodes grouped by when demand started,
# keeping their cohort stable as later facts arrive. Reply activity remains
# message-derived because active episodes do not have a terminal snapshot yet.
class Captain::AssistantOverviewStatsBuilder
  DURABLE_RESOLUTION_WINDOW = 7.days
  SECONDS_SAVED_PER_REPLY = 2.minutes.to_i
  USAGE_LIMIT_REASON = 'usage_limit'.freeze

  # Usage-limit handoffs represent blocked demand. Every other handoff,
  # including an unclassified one, means Captain participated.
  INVOLVED_SQL = '(first_captain_reply_at IS NOT NULL OR (handoff_at IS NOT NULL AND ' \
                 "handoff_reason_category IS DISTINCT FROM '#{USAGE_LIMIT_REASON}'))".freeze
  AUTONOMOUS_SQL = '(resolved_at IS NOT NULL AND first_captain_reply_at IS NOT NULL AND handoff_at IS NULL ' \
                   'AND (first_human_reply_at IS NULL OR first_human_reply_at > resolved_at))'.freeze
  ASSISTED_SQL = "(resolved_at IS NOT NULL AND #{INVOLVED_SQL} AND NOT #{AUTONOMOUS_SQL})".freeze
  HANDOFF_SQL = "(#{INVOLVED_SQL} AND handoff_at IS NOT NULL)".freeze
  REOPENED_AUTONOMOUS_SQL = "(#{AUTONOMOUS_SQL} AND ended_at IS NOT NULL AND ended_at > resolved_at)".freeze
  DURABLE_SQL = "(ended_at IS NULL OR ended_at >= resolved_at + INTERVAL '7 days')".freeze

  PACKED_METRICS = {
    conversations_handled: %i[involved percent],
    auto_resolution_rate: %i[auto_resolution_rate point],
    autonomous_resolutions: %i[autonomous percent],
    handoff_rate: %i[handoff_rate point],
    handoff_count: %i[handoffs percent],
    hours_saved: %i[hours_saved absolute],
    reopen_rate: %i[reopen_rate point],
    conversation_depth: %i[conversation_depth absolute],
    durable_resolution_rate: %i[durable_rate point],
    autonomous_csat_score: %i[autonomous_csat absolute],
    assisted_csat_score: %i[assisted_csat absolute],
    median_resolution_seconds: %i[median_resolution absolute]
  }.freeze

  attr_reader :assistant, :account

  delegate :range, :period, to: :window

  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def metrics
    rows = outcome_window_rows
    messages = message_window_rows
    current = window_metrics(rows[:current], messages[:current])
    previous = window_metrics(rows[:previous], messages[:previous])

    PACKED_METRICS.transform_values { |(key, mode)| pack(current[key], previous[key], mode) }.merge(
      human_only_csat_score: pack(human_only_csat(window.current), human_only_csat(window.previous), :absolute)
    )
  end

  private

  attr_reader :window

  def window_metrics(row, message_row)
    involved, autonomous, handoffs, reopened, assessable, durable, autonomous_csat, assisted_csat, resolution = row
    public_replies, reply_conversations = message_row

    {
      involved: involved,
      autonomous: autonomous,
      auto_resolution_rate: rate(autonomous, involved),
      handoffs: handoffs,
      handoff_rate: rate(handoffs, involved),
      hours_saved: (public_replies * SECONDS_SAVED_PER_REPLY / 3600.0).round,
      reopen_rate: rate(reopened, autonomous),
      conversation_depth: reply_conversations.zero? ? 0 : (public_replies.to_f / reply_conversations).round(1),
      durable_rate: rate(durable, assessable),
      autonomous_csat: autonomous_csat.to_f.round(2),
      assisted_csat: assisted_csat.to_f.round(2),
      median_resolution: resolution.to_i
    }
  end

  # Both outcome windows are computed in one scan. Day-based windows share an
  # endpoint, so the previous range excludes that boundary to avoid counting an
  # episode in both cohorts.
  def outcome_window_rows
    current_aggregates = window_aggregates(window_clause(window.current, column: 'started_at'))
    previous_aggregates = window_aggregates(
      window_clause(window.previous, column: 'started_at', exclude_end: shared_boundary?)
    )
    row = outcomes_scope(full_span).reorder(nil).pick(
      *(current_aggregates + previous_aggregates).map { |sql| Arel.sql(sql) }
    )
    aggregate_count = current_aggregates.length

    { current: row.first(aggregate_count), previous: row.last(aggregate_count) }
  end

  def window_aggregates(clause)
    assessable = "#{AUTONOMOUS_SQL} AND resolved_at <= #{quote(durable_cutoff)}"

    [
      "COUNT(*) FILTER (WHERE #{clause} AND #{INVOLVED_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{AUTONOMOUS_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{HANDOFF_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{REOPENED_AUTONOMOUS_SQL})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{assessable})",
      "COUNT(*) FILTER (WHERE #{clause} AND #{assessable} AND #{DURABLE_SQL})",
      "AVG(csat_rating) FILTER (WHERE #{clause} AND #{AUTONOMOUS_SQL} AND csat_rating IS NOT NULL)",
      "AVG(csat_rating) FILTER (WHERE #{clause} AND #{ASSISTED_SQL} AND csat_rating IS NOT NULL)",
      'percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (resolved_at - started_at))) ' \
      "FILTER (WHERE #{clause} AND #{INVOLVED_SQL} AND resolved_at IS NOT NULL)"
    ]
  end

  # Reply-based metrics retain their event-time meaning. Outcome reply counts
  # are snapshotted only at terminal events, so active episodes can be stale.
  def message_window_rows
    current_clause = window_clause(window.current, column: 'created_at')
    previous_clause = window_clause(window.previous, column: 'created_at', exclude_end: shared_boundary?)
    public_reply = "message_type = #{Message.message_types[:outgoing]} AND private = false"

    row = assistant_messages.reorder(nil).pick(
      Arel.sql("COUNT(*) FILTER (WHERE #{current_clause} AND #{public_reply})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{current_clause} AND #{public_reply})"),
      Arel.sql("COUNT(*) FILTER (WHERE #{previous_clause} AND #{public_reply})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{previous_clause} AND #{public_reply})")
    )

    { current: row[0..1], previous: row[2..3] }
  end

  # Account-wide CSAT from conversations where no Captain assistant ever
  # participated provides the comparison baseline.
  def human_only_csat(range)
    involved_conversations = ConversationOutcome
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
    account.conversation_outcomes.where(assistant_id: assistant.id, started_at: range)
  end

  def assistant_messages
    account.messages.where(sender_type: 'Captain::Assistant', sender_id: assistant.id, created_at: full_span)
  end

  def full_span
    window.previous.first..window.current.last
  end

  def durable_cutoff
    @durable_cutoff ||= Time.current - DURABLE_RESOLUTION_WINDOW
  end

  def shared_boundary?
    window.previous.last == window.current.first
  end

  def window_clause(range, column:, exclude_end: false)
    end_operator = exclude_end ? '<' : '<='
    "#{column} >= #{quote(range.first)} AND #{column} #{end_operator} #{quote(range.last)}"
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
    else
      (current - previous).round(1)
    end
  end
end
