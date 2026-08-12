# Shared query-time classifications for Captain conversation outcome reporting.
module Captain::AssistantOutcomeClassification
  DURABLE_RESOLUTION_WINDOW = 7.days
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
  REOPENED_WITHIN_7_DAYS_SQL = "(#{REOPENED_AUTONOMOUS_SQL} AND ended_at < resolved_at + INTERVAL '7 days')".freeze
  DURABLE_SQL = "(ended_at IS NULL OR ended_at >= resolved_at + INTERVAL '7 days')".freeze
end
