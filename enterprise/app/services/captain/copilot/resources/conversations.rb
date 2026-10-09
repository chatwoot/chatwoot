class Captain::Copilot::Resources::Conversations < Captain::Copilot::Resources::BaseResource
  NAME = 'conversations'.freeze
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = {
    status: { type: 'string', enum: Conversation.statuses.keys }, priority: { type: 'string', enum: Conversation.priorities.keys },
    inbox_id: { type: 'integer' }, assignee_id: { type: 'integer' }, team_id: { type: 'integer' }, contact_id: { type: 'integer' },
    labels: { type: 'array', items: { type: 'string' } }
  }.freeze
  SOURCES = {
    'conversations' => ->(ids) { Conversation.where(id: ids) },
    'contacts' => ->(ids) { Conversation.where(contact_id: ids) },
    'messages' => ->(ids) { Conversation.where(id: Message.where(id: ids).select(:conversation_id)) }
  }.freeze
  COLUMNS = ['Status', 'Labels', 'Last activity'].freeze
  PRELOAD = [].freeze

  def scope
    accessible_conversations(account: @account, user: @user)
  end

  def filter(relation, filters)
    relation = relation.where(filters.slice('status', 'priority', 'inbox_id', 'assignee_id', 'team_id', 'contact_id'))
    filters['labels'].present? ? relation.tagged_with(filters['labels'], any: true) : relation
  end

  def row(conversation)
    { label: "##{conversation.display_id}", url: url("conversations/#{conversation.display_id}"),
      values: [conversation.status, conversation.label_list.join(', '), conversation.last_activity_at&.to_date] }
  end
end
