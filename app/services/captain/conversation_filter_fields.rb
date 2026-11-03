# The conversation filter fields Jev may recommend, each with the account's real values as options.
# Free-text fields are left out because Jev can only pick from options.
class Captain::ConversationFilterFields
  include Captain::FilterFieldBuilder

  SUBJECT = 'support conversations'.freeze

  pattr_initialize [:account!, :user!]

  def subject
    SUBJECT
  end

  def all
    (enum_fields + record_fields + date_fields + list_attribute_fields(:conversation_attribute)).first(MAX_FIELDS)
  end

  private

  def enum_fields
    [
      field('status', 'Status', EQUALITY_OPERATORS, Conversation.statuses.keys.map { |status| [status, status] }, multiple: true),
      field('priority', 'Priority', EQUALITY_OPERATORS, Conversation.priorities.keys.map { |priority| [priority, priority] },
            multiple: true, ordered: true)
    ]
  end

  def record_fields
    [
      field('assignee_id', 'Assigned agent', PRESENCE_OPERATORS, options(account.users, :id, :name)),
      field('inbox_id', 'Inbox', PRESENCE_OPERATORS, options(user.assigned_inboxes, :id, :name)),
      field('team_id', 'Team', PRESENCE_OPERATORS, options(account.teams, :id, :name)),
      field('labels', 'Label', PRESENCE_OPERATORS, options(account.labels, :title, :title), multiple: true),
      field('campaign_id', 'Campaign', PRESENCE_OPERATORS, options(account.campaigns, :id, :title))
    ]
  end

  def date_fields
    [date_field('created_at', 'Created date'), date_field('last_activity_at', 'Last activity date')]
  end
end
