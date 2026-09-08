# Shared query-time classifications for Captain conversation outcome reporting.
module Captain::AssistantOutcomeClassification
  DURABLE_RESOLUTION_WINDOW = 7.days
  USAGE_LIMIT_REASON = 'usage_limit'.freeze

  private

  # A usage-limit handoff is blocked demand only when Captain never replied, so
  # it does not make the episode involved. If Captain replied before the quota
  # ran out, the episode remains involved and the later transfer is a real
  # handoff. Every non-usage-limit handoff, including an unclassified one, also
  # means Captain participated.
  def involved(table)
    table[:first_captain_reply_at].not_eq(nil).or(
      table[:handoff_at].not_eq(nil).and(
        table[:handoff_reason_category].is_distinct_from(USAGE_LIMIT_REASON)
      )
    )
  end

  def autonomous(table)
    table[:resolved_at].not_eq(nil)
                       .and(table[:first_captain_reply_at].not_eq(nil))
                       .and(table[:handoff_at].eq(nil))
                       .and(
                         table[:first_human_reply_at].eq(nil).or(
                           table[:first_human_reply_at].gt(table[:resolved_at])
                         )
                       )
  end

  def assisted(table)
    table[:resolved_at].not_eq(nil)
                       .and(involved(table))
                       .and(autonomous(table).not)
  end

  def handoff(table)
    # Intentionally includes usage-limit transfers when a prior Captain reply
    # made the episode involved; only pre-participation quota blocks are excluded.
    involved(table).and(table[:handoff_at].not_eq(nil))
  end

  def reopened_autonomous(table)
    autonomous(table)
      .and(table[:ended_at].not_eq(nil))
      .and(table[:ended_at].gt(table[:resolved_at]))
  end

  def reopened_within_7_days(table)
    reopened_autonomous(table).and(resolution_duration(table).lt(DURABLE_RESOLUTION_WINDOW.to_i))
  end

  def durable(table)
    table[:ended_at].eq(nil).or(
      resolution_duration(table).gteq(DURABLE_RESOLUTION_WINDOW.to_i)
    )
  end

  def resolution_duration(table)
    (table[:ended_at] - table[:resolved_at]).extract(:epoch)
  end
end
