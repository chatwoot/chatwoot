# A conversation counts as handled by whoever sent at least one public message
# in it during the period. It is attributed to the sender, not to the assignee,
# so a conversation two agents replied to counts once for each of them, and an
# agent who never touched the conversations assigned to them handles none.
module Reports::HandledConversations
  METRIC = 'handled_conversations_count'.freeze

  SUMMARY_GROUP_BY = {
    'account' => 'messages.account_id',
    'agent' => 'messages.sender_id',
    'inbox' => 'messages.inbox_id',
    'team' => 'conversations.team_id'
  }.freeze

  module_function

  def metric?(name)
    name.to_s == METRIC
  end

  # The SQL side of Message#human_response?, minus private notes: a reply a
  # person wrote to the customer, from the dashboard or echoed from the native
  # app. Reactions, automations and campaigns are left out even when they carry
  # a User as sender, which a live chat campaign does. An echo has no sender, so
  # it counts for its inbox and team but for no agent. `#>>'{}'` unwraps the
  # double-encoded json column, see Message.hide_removed_reactions.
  #
  # It is also the predicate of index_messages_on_handled_conversations, there without the
  # `messages.` the team report needs here to tell its columns from the joined conversation's:
  # a month on a busy account is over a million rows, and the partial index is what
  # lets Postgres answer from the index alone. Change one and the other has to follow,
  # which the spec on the query plan holds.
  PREDICATE = <<~SQL.squish.freeze
    messages.message_type = 1 AND messages.private = false
    AND ((messages.content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true') IS NOT TRUE
    AND COALESCE((messages.content_attributes#>>'{}')::jsonb->>'automation_rule_id', '') = ''
    AND COALESCE(messages.additional_attributes->>'campaign_id', '') = ''
    AND (messages.sender_type = 'User' OR COALESCE((messages.content_attributes#>>'{}')::jsonb->>'external_echo', '') NOT IN ('', 'false'))
  SQL

  def messages(scope)
    scope.where(PREDICATE).unscope(:order)
  end

  # One row per conversation, ready for `count` (and groupdate's grouped count).
  def distinct_conversations(scope)
    messages(scope).select(:conversation_id).distinct
  end

  # { dimension_id => handled conversations } for a summary grouped by dimension.
  def summary_counts(account:, dimension_type:, range:, filters: {})
    group_by = SUMMARY_GROUP_BY[dimension_type.to_s]
    return {} if group_by.blank?

    scope = messages(account.messages.where(created_at: range))
    scope = scope.joins(:conversation) if dimension_type.to_s == 'team'
    scope = scope.where(inbox_id: filters[:inbox_id]) if filters[:inbox_id].present?
    scope = scope.where(sender_id: filters[:user_id]) if filters[:user_id].present?

    scope.group(group_by).distinct.count(:conversation_id)
  end
end
