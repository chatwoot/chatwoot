# The conversation filter fields Jev may recommend, each with the account's real values as options.
# Free-text fields are left out because Jev can only pick from options.
class Captain::ConversationFilterFields
  MAX_FIELDS = 40
  MAX_OPTIONS = 60
  EQUALITY_OPERATORS = %w[equal_to not_equal_to].freeze
  PRESENCE_OPERATORS = %w[equal_to not_equal_to is_present is_not_present].freeze
  DATE_OPERATORS = %w[is_greater_than days_before].freeze
  TRAITS = { multiple: false, ordered: false, date: false }.freeze

  pattr_initialize [:account!, :user!]

  def all
    (enum_fields + record_fields + date_fields + custom_attribute_fields).first(MAX_FIELDS)
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
    [
      field('created_at', 'Created date', DATE_OPERATORS, [], date: true),
      field('last_activity_at', 'Last activity date', DATE_OPERATORS, [], date: true)
    ]
  end

  def custom_attribute_fields
    account.custom_attribute_definitions.conversation_attribute.list.order(:id).map do |definition|
      values = definition.attribute_values.first(MAX_OPTIONS).map { |value| [value, value] }
      field(definition.attribute_key, definition.attribute_display_name, EQUALITY_OPERATORS, values)
    end
  end

  def options(relation, value_column, label_column)
    relation.order(:id).limit(MAX_OPTIONS).pluck(value_column, label_column)
  end

  # `multiple` marks fields whose filter accepts several values at once.
  # `ordered` marks fields whose options run from lowest to highest, such as priority.
  # `date` marks timestamp fields, whose values come from a number of days in the description.
  def field(key, label, operators, values, **traits)
    {
      key: key, label: label, operators: operators,
      options: values.map { |value, name| { value: value, label: name.to_s } }
    }.merge(TRAITS, traits.slice(*TRAITS.keys))
  end
end
