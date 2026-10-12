class Captain::Copilot::Resources::Conversations < Captain::Copilot::Resources::BaseResource
  NAME = 'conversations'.freeze
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = {
    status: { type: 'string', enum: Conversation.statuses.keys }, priority: { type: 'string', enum: Conversation.priorities.keys },
    inbox_id: { type: 'integer', minimum: 1 }, assignee_id: { type: %w[integer null], minimum: 1, description: 'null for unassigned' },
    team_id: { type: %w[integer null], minimum: 1, description: 'null for no team' }, contact_id: { type: 'integer', minimum: 1 },
    labels: { type: 'array', items: { type: 'string' } }
  }.freeze
  SOURCES = {
    'conversations' => ->(ids) { Conversation.where(id: ids) },
    'contacts' => ->(ids) { Conversation.where(contact_id: ids) },
    'messages' => ->(ids) { Conversation.where(id: Message.where(id: ids).select(:conversation_id)) }
  }.freeze
  COLUMNS = ['Status', 'Labels', 'Last activity'].freeze
  PRELOAD = [].freeze
  GROUPS = %w[status priority inbox assignee team label].freeze

  def scope
    accessible_conversations(account: @account, user: @user)
  end

  def filter(relation, filters)
    relation = relation.where(filters.slice('status', 'priority', 'inbox_id', 'assignee_id', 'team_id', 'contact_id'))
    filters['labels'].present? ? relation.tagged_with(filters['labels'], any: true) : relation
  end

  def counts_by(relation, group)
    case group
    when 'status', 'priority' then column_counts(relation, group, none: 'None')
    when 'inbox' then column_counts(relation, :inbox_id, none: 'No inbox', names: @account.inboxes)
    when 'assignee' then column_counts(relation, :assignee_id, none: 'Unassigned', names: @account.users)
    when 'team' then column_counts(relation, :team_id, none: 'No team', names: @account.teams)
    when 'label' then label_counts(relation)
    end
  end

  def row(conversation)
    { label: "##{conversation.display_id}", url: url("conversations/#{conversation.display_id}"),
      values: [conversation.status, conversation.label_list.join(', '), conversation.last_activity_at&.to_date] }
  end
end
