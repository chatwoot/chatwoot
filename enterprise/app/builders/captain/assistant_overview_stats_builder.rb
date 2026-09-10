# Computes the complete per-assistant metric set for the Captain overview.
# Funnel and outcome metrics use episodes grouped by when demand started,
# keeping their cohort stable as later facts arrive. Reply activity remains
# message-derived because active episodes do not have a terminal snapshot yet.
class Captain::AssistantOverviewStatsBuilder
  include Captain::AssistantOutcomeClassification

  SECONDS_SAVED_PER_REPLY = 2.minutes.to_i

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
    current_aggregates = window_aggregates(window_predicate(window.current, table: outcomes_table, column: :started_at))
    previous_aggregates = window_aggregates(
      window_predicate(window.previous, table: outcomes_table, column: :started_at, exclude_end: shared_boundary?)
    )
    row = outcomes_scope(full_span).reorder(nil).pick(*(current_aggregates + previous_aggregates))
    aggregate_count = current_aggregates.length

    { current: row.first(aggregate_count), previous: row.last(aggregate_count) }
  end

  def window_aggregates(predicate)
    volume_aggregates(predicate) + durability_aggregates(predicate) + csat_aggregates(predicate) + [median_resolution(predicate)]
  end

  def volume_aggregates(predicate)
    [
      filtered_count(predicate.and(involved(outcomes_table))),
      filtered_count(predicate.and(autonomous(outcomes_table))),
      filtered_count(predicate.and(handoff(outcomes_table))),
      filtered_count(predicate.and(reopened_autonomous(outcomes_table)))
    ]
  end

  def durability_aggregates(predicate)
    assessable = autonomous(outcomes_table).and(outcomes_table[:resolved_at].lteq(durable_cutoff))

    [
      filtered_count(predicate.and(assessable)),
      filtered_count(predicate.and(assessable).and(durable(outcomes_table)))
    ]
  end

  def csat_aggregates(predicate)
    [
      filtered_average(predicate.and(autonomous(outcomes_table))),
      filtered_average(predicate.and(assisted(outcomes_table)))
    ]
  end

  # Reply-based metrics retain their event-time meaning. Outcome reply counts
  # are snapshotted only at terminal events, so active episodes can be stale.
  def message_window_rows
    current_predicate = window_predicate(window.current, table: messages_table, column: :created_at)
    previous_predicate = window_predicate(
      window.previous, table: messages_table, column: :created_at, exclude_end: shared_boundary?
    )
    aggregates = [current_predicate, previous_predicate].flat_map do |predicate|
      message_aggregates(predicate.and(public_reply_predicate))
    end

    row = assistant_messages.reorder(nil).pick(*aggregates)

    { current: row[0..1], previous: row[2..3] }
  end

  def message_aggregates(predicate)
    [
      filtered_count(predicate),
      messages_table[:conversation_id].count(true).filter(predicate)
    ]
  end

  def public_reply_predicate
    messages_table[:message_type].eq(Message.message_types[:outgoing]).and(messages_table[:private].eq(false))
  end

  # Account-wide CSAT from conversations where no Captain assistant ever
  # participated provides the comparison baseline.
  def human_only_csat(range)
    involved_conversations = ConversationOutcome
                             .where(account_id: account.id)
                             .where(involved(outcomes_table))
                             .select(:conversation_id)
    score = account.csat_survey_responses
                   .where(created_at: range)
                   .where.not(conversation_id: involved_conversations)
                   .average(:rating)

    score&.to_f&.round(2)
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

  def window_predicate(range, table:, column:, exclude_end: false)
    starts_in_window = table[column].gteq(range.first)
    ends_in_window = exclude_end ? table[column].lt(range.last) : table[column].lteq(range.last)

    starts_in_window.and(ends_in_window)
  end

  def median_resolution(predicate)
    duration = (outcomes_table[:resolved_at] - outcomes_table[:started_at]).extract(:epoch)
    percentile = Arel::Nodes::NamedFunction.new('percentile_cont', [Arel::Nodes.build_quoted(0.5)])
    within_group = Arel::Nodes::InfixOperation.new(
      'WITHIN GROUP', percentile, Arel::Nodes::Window.new.order(duration)
    )

    Arel::Nodes::Filter.new(
      within_group,
      predicate.and(involved(outcomes_table)).and(outcomes_table[:resolved_at].not_eq(nil))
    )
  end

  def filtered_count(predicate)
    Arel.star.count.filter(predicate)
  end

  def filtered_average(predicate)
    outcomes_table[:csat_rating].average.filter(predicate.and(outcomes_table[:csat_rating].not_eq(nil)))
  end

  def outcomes_table
    @outcomes_table ||= ConversationOutcome.arel_table
  end

  def messages_table
    @messages_table ||= Message.arel_table
  end

  def rate(numerator, denominator)
    return 0 if denominator.zero?

    (numerator.to_f / denominator * 100).round(1)
  end

  def pack(current, previous, mode)
    { current: current, previous: previous, trend: trend(current, previous, mode) }
  end

  def trend(current, previous, mode)
    return if current.nil? || previous.nil?

    case mode
    when :percent
      previous.zero? ? 0 : ((current - previous).to_f / previous * 100).round(1)
    else
      (current - previous).round(1)
    end
  end
end
