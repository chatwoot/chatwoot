# Computes per-assistant overview metrics for the Captain Overview page.
# Each metric is returned for the current window and the previous equal-length
# window, plus a derived trend.
#
# Handled, resolution, handoff, and reopen metrics come from
# captain_conversation_outcomes, each anchored on its own event timestamp
# (reply span, resolved_at, handoff_at, last_reopened_at) so completed windows
# stay frozen and the current window isn't dragged down by conversations that
# haven't finished yet. Classifications are the model's query-time predicates.
# The reply-derived metrics (hours saved, depth) stay on the messages table,
# which is the only per-message activity ledger. Both sources compute the two
# windows in a single scan via FILTER aggregation.
class Captain::AssistantStatsBuilder
  # Assumed agent effort displaced by each public assistant reply. Reporting data
  # only captures reply latency (customer wait time), not handling effort, so hours
  # saved is a count-times-assumed-effort estimate rather than a measured duration.
  SECONDS_SAVED_PER_REPLY = 2.minutes.to_i

  attr_reader :assistant, :account

  delegate :range, :period, to: :window

  # `range` is either a day count ('7', '30', '90') or a named period
  # ('this_month', 'last_month'). `timezone_offset` is the viewer's UTC offset in
  # hours (as the reports API sends it), so month/day boundaries anchor to the
  # viewer's day rather than UTC. Both windows are resolved by AssistantStatsWindow.
  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil, suggestions_scope: nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
    @suggestions_scope = suggestions_scope || assistant.faq_suggestions
  end

  def metrics
    messages = message_window_metrics
    outcomes = outcome_window_metrics
    current = window_metrics(outcomes[:current], messages[:current])
    previous = window_metrics(outcomes[:previous], messages[:previous])

    build_metrics(current, previous)
  end

  # Approved FAQ, open suggestion, and document counts in a single round trip.
  def faq_stats
    approved, suggestions, documents = Captain::AssistantResponse.by_assistant(assistant.id).reorder(nil).pick(
      Arel.sql("COUNT(*) FILTER (WHERE status = #{Captain::AssistantResponse.statuses['approved']})"),
      Arel.sql("(#{open_suggestion_count_sql})"),
      Arel.sql("(SELECT COUNT(*) FROM captain_documents WHERE assistant_id = #{assistant.id.to_i})")
    )
    total = approved + suggestions

    {
      approved: approved,
      suggestions: suggestions,
      documents: documents,
      coverage: total.zero? ? 0 : (approved.to_f / total * 100).round
    }
  end

  private

  attr_reader :window, :suggestions_scope

  def current_range
    window.current
  end

  def previous_range
    window.previous
  end

  def build_metrics(current, previous)
    {
      conversations_handled: pack(current[:handled], previous[:handled], :percent),
      auto_resolution_rate: pack(current[:auto_resolution], previous[:auto_resolution], :point),
      handoff_rate: pack(current[:handoff], previous[:handoff], :point),
      hours_saved: pack(current[:hours_saved], previous[:hours_saved], :percent),
      reopen_rate: pack(current[:reopen], previous[:reopen], :point),
      conversation_depth: pack(current[:depth], previous[:depth], :absolute)
    }
  end

  # Combines the per-window outcome counts with the message-derived metrics for one window.
  def window_metrics(outcome_counts, message_counts)
    handled = outcome_counts[:handled]
    public_count = message_counts[:public_count]
    depth_conversations = message_counts[:depth_conversations]

    {
      handled: handled,
      auto_resolution: rate(outcome_counts[:autonomous], handled),
      handoff: rate(outcome_counts[:handoff], handled),
      hours_saved: (public_count * SECONDS_SAVED_PER_REPLY / 3600.0).round,
      reopen: rate(outcome_counts[:reopened], outcome_counts[:autonomous]),
      depth: depth_conversations.zero? ? 0 : (public_count.to_f / depth_conversations).round(1)
    }
  end

  # One scan over the assistant's outcome rows computes all four counts for both
  # windows, each anchored on its own event timestamp.
  def outcome_window_metrics
    per_window = [current_range, previous_range].flat_map { |range| outcome_aggregates(range) }
    row = assistant.conversation_outcomes.reorder(nil).pick(*per_window.map { |sql| Arel.sql(sql) })

    {
      current: { handled: row[0], autonomous: row[1], handoff: row[2], reopened: row[3] },
      previous: { handled: row[4], autonomous: row[5], handoff: row[6], reopened: row[7] }
    }
  end

  def outcome_aggregates(range)
    autonomous = Captain::ConversationOutcome::AUTONOMOUS_SQL
    # Handled: Captain's reply activity overlapped the window. Resolutions,
    # handoffs, and reopens count where the event itself landed; usage-limit
    # handoffs are blocked demand, not Captain activity, so they stay out of
    # both the handled set (no replies) and the handoff numerator.
    handled = "first_captain_reply_at <= #{quote(range.last)} AND last_captain_reply_at >= #{quote(range.first)}"
    resolved = between('resolved_at', range)

    [
      "COUNT(*) FILTER (WHERE #{handled})",
      "COUNT(*) FILTER (WHERE #{resolved} AND #{autonomous})",
      "COUNT(*) FILTER (WHERE #{between('handoff_at', range)} AND handoff_reason_category != 'usage_limit')",
      "COUNT(*) FILTER (WHERE #{resolved} AND #{autonomous} AND #{between('last_reopened_at', range)})"
    ]
  end

  # One scan over the assistant's messages computes the public-reply count and
  # depth-conversation count for both windows via conditional aggregation.
  def message_window_metrics
    public_clause = "message_type = #{Message.message_types[:outgoing]} AND private = false"
    cur = between('created_at', current_range)
    prev = between('created_at', previous_range)

    row = assistant_messages(full_span).reorder(nil).pick(
      Arel.sql("COUNT(*) FILTER (WHERE #{cur} AND #{public_clause})"),
      Arel.sql("COUNT(*) FILTER (WHERE #{prev} AND #{public_clause})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{cur} AND #{public_clause})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{prev} AND #{public_clause})")
    )

    {
      current: { public_count: row[0], depth_conversations: row[2] },
      previous: { public_count: row[1], depth_conversations: row[3] }
    }
  end

  def assistant_messages(range)
    account.messages.where(sender_type: 'Captain::Assistant', sender_id: assistant.id, created_at: range)
  end

  # Span covering both windows so a single scan can split them with FILTER.
  def full_span
    [current_range.first, previous_range.first].min..current_range.last
  end

  def between(column, range)
    "#{column} >= #{quote(range.first)} AND #{column} <= #{quote(range.last)}"
  end

  def quote(value)
    account.class.connection.quote(value)
  end

  def open_suggestion_count_sql
    suggestions_scope.where(assistant_id: assistant.id).open.reorder(nil).select('COUNT(*)').to_sql
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
