# Computes per-assistant overview metrics for the Captain Overview page.
# Each metric is returned for the current window and the previous equal-length
# window, plus a derived trend.
#
# Queries are batched to cut round trips: the message-derived counts (handled,
# public replies, depth) and the average reply time are each computed for both
# windows in a single scan via conditional FILTER aggregation.
class Captain::AssistantStatsBuilder
  RESOLVED_EVENT_NAMES = %w[conversation_captain_inference_resolved conversation_bot_resolved].freeze
  HANDOFF_EVENT_NAMES = %w[conversation_captain_inference_handoff conversation_bot_handoff].freeze
  BOT_RESOLVED_EVENT_NAME = 'conversation_bot_resolved'.freeze

  attr_reader :assistant, :account

  delegate :range, :period, to: :window

  # `range` is either a day count ('7', '30', '90') or a named period
  # ('this_month', 'last_month'). `timezone_offset` is the viewer's UTC offset in
  # hours (as the reports API sends it), so month/day boundaries anchor to the
  # viewer's day rather than UTC. Both windows are resolved by AssistantStatsWindow.
  def initialize(assistant, range = Captain::AssistantStatsWindow::DEFAULT_RANGE, timezone_offset = nil)
    @assistant = assistant
    @account = assistant.account
    @window = Captain::AssistantStatsWindow.new(range, timezone_offset)
  end

  def metrics
    messages = message_window_metrics
    reply_times = avg_reply_times
    current = window_metrics(current_range, messages[:current], reply_times[:current])
    previous = window_metrics(previous_range, messages[:previous], reply_times[:previous])

    build_metrics(current, previous)
  end

  private

  attr_reader :window

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
      conversation_depth: pack(current[:depth], previous[:depth], :absolute),
      knowledge: knowledge
    }
  end

  # Combines the per-window message counts and reply time with the reporting-event metrics for one window.
  def window_metrics(range, message_counts, avg_reply)
    handled = message_counts[:handled]
    public_count = message_counts[:public_count]
    depth_conversations = message_counts[:depth_conversations]
    resolution = resolution_counts(range)

    {
      handled: handled,
      auto_resolution: rate(resolution[:resolved], handled),
      handoff: rate(resolution[:handoff], handled),
      hours_saved: (public_count * avg_reply / 3600.0).round,
      reopen: reopen_rate(range),
      depth: depth_conversations.zero? ? 0 : (public_count.to_f / depth_conversations).round(1)
    }
  end

  # One scan over the assistant's messages computes handled, public-reply count,
  # and depth-conversation count for both windows via conditional aggregation.
  def message_window_metrics
    public_clause = "message_type = #{Message.message_types[:outgoing]} AND private = false"
    cur = window_clause(current_range)
    prev = window_clause(previous_range)

    row = handled_scope(full_span).reorder(nil).pick(
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{cur})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{prev})"),
      Arel.sql("COUNT(*) FILTER (WHERE #{cur} AND #{public_clause})"),
      Arel.sql("COUNT(*) FILTER (WHERE #{prev} AND #{public_clause})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{cur} AND #{public_clause})"),
      Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{prev} AND #{public_clause})")
    )

    {
      current: { handled: row[0], public_count: row[2], depth_conversations: row[4] },
      previous: { handled: row[1], public_count: row[3], depth_conversations: row[5] }
    }
  end

  # Average reply time (seconds) for both windows in one scan.
  def avg_reply_times
    row = account.reporting_events.where(name: 'reply_time', created_at: full_span).reorder(nil).pick(
      Arel.sql("AVG(value) FILTER (WHERE #{window_clause(current_range)})"),
      Arel.sql("AVG(value) FILTER (WHERE #{window_clause(previous_range)})")
    )
    { current: row[0].to_f, previous: row[1].to_f }
  end

  # Resolved and handed-off conversation counts for one window, in a single scan
  # of the handled set's reporting events.
  def resolution_counts(range)
    row = account.reporting_events
                 .where(name: RESOLVED_EVENT_NAMES + HANDOFF_EVENT_NAMES,
                        created_at: range,
                        conversation_id: handled_scope(range).select(:conversation_id))
                 .reorder(nil)
                 .pick(
                   Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE #{resolved_clause(range)})"),
                   Arel.sql("COUNT(DISTINCT conversation_id) FILTER (WHERE name IN (#{quoted(HANDOFF_EVENT_NAMES)}))")
                 )
    { resolved: row[0], handoff: row[1] }
  end

  # A countable resolve is any inference resolve, or a bot resolve on a conversation
  # with no handoff in the window. conversation_bot_resolved fires on any resolve
  # without an agent message (reporting_event_listener), so a handed-off conversation
  # that goes quiet and gets closed would otherwise count as an auto-resolution too;
  # the reports bot_resolutions metric applies the same exclusion (:exclude_bot_handoffs).
  def resolved_clause(range)
    "name IN (#{quoted(RESOLVED_EVENT_NAMES)}) AND #{bot_resolve_handoff_exclusion(range)}"
  end

  def bot_resolve_handoff_exclusion(range)
    "NOT (name = #{quote(BOT_RESOLVED_EVENT_NAME)} AND conversation_id IN (#{handoff_conversation_ids(range).to_sql}))"
  end

  def handoff_conversation_ids(range)
    account.reporting_events.where(name: HANDOFF_EVENT_NAMES, created_at: range).select(:conversation_id)
  end

  # Conversations the assistant participated in (authored any message).
  def handled_scope(range)
    account.messages.where(sender_type: 'Captain::Assistant', sender_id: assistant.id, created_at: range)
  end

  # Span covering both windows so a single scan can split them with FILTER.
  def full_span
    [current_range.first, previous_range.first].min..current_range.last
  end

  def window_clause(range)
    "created_at >= #{quote(range.first)} AND created_at <= #{quote(range.last)}"
  end

  def quote(value)
    account.class.connection.quote(value)
  end

  def quoted(values)
    values.map { |value| quote(value) }.join(', ')
  end

  # Of the conversations Captain auto-resolved, the share reopened afterwards. The cohort is
  # derived from the assistant's handled conversations (not current inbox membership) so a later
  # inbox reassignment doesn't drop historical resolves, and covers both the evaluated (inference)
  # and time-based (bot) resolve paths so the denominator matches auto_resolution_rate.
  def reopen_rate(range)
    resolved_scope = account.reporting_events
                            .where(name: RESOLVED_EVENT_NAMES, created_at: range,
                                   conversation_id: handled_scope(range).select(:conversation_id))
                            .where(bot_resolve_handoff_exclusion(range))
    # event_end_time on a reopen is when it actually reopened. Join it to the conversation's own
    # Captain resolves and keep only reopens at/after one of them, so a human resolve/reopen earlier
    # in the same window isn't mistaken for a reopen-after-Captain-resolve. (Comparing the reopen's
    # start time instead would misfire: the inference event is dispatched just after the generic
    # conversation_resolved that seeds event_start_time, so it can land after the reopen's start.)
    # The reopen itself must also fall inside the window, so a completed range (last_month, the
    # previous window) doesn't count reopens that happened after it ended.
    reopened = account.reporting_events
                      .where(name: 'conversation_opened')
                      .where('reporting_events.value > 0')
                      .where('reporting_events.event_end_time <= ?', range.last)
                      .joins("INNER JOIN (#{resolved_scope.to_sql}) resolves " \
                             'ON resolves.conversation_id = reporting_events.conversation_id ' \
                             'AND reporting_events.event_end_time >= resolves.event_end_time')
                      .distinct.count('reporting_events.conversation_id')
    rate(reopened, resolved_scope.distinct.count(:conversation_id))
  end

  # Approved/pending FAQ counts and the document total in a single round trip.
  def knowledge
    approved, pending, documents = Captain::AssistantResponse.by_assistant(assistant.id).reorder(nil).pick(
      Arel.sql("COUNT(*) FILTER (WHERE status = #{Captain::AssistantResponse.statuses['approved']})"),
      Arel.sql("COUNT(*) FILTER (WHERE status = #{Captain::AssistantResponse.statuses['pending']})"),
      Arel.sql("(SELECT COUNT(*) FROM captain_documents WHERE assistant_id = #{assistant.id.to_i})")
    )
    total = approved + pending

    {
      approved: approved,
      pending: pending,
      documents: documents,
      coverage: total.zero? ? 0 : (approved.to_f / total * 100).round
    }
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
