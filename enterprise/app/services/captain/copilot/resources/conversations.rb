class Captain::Copilot::Resources::Conversations < Captain::Copilot::Resources::BaseResource
  NAME = 'conversations'.freeze
  MODEL = Conversation
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = { labels: { type: 'array', minItems: 1, items: { type: 'string' }, description: 'Conversations with any of these labels' } }.freeze
  SOURCES = {}.freeze
  COLUMNS = ['Status', 'Assignee', 'Labels', 'Last activity'].freeze
  PRELOAD = [:assignee].freeze
  GROUPS = %w[label].freeze

  def scope
    accessible_conversations(account: @account, user: @user)
  end

  def filter(relation, filters)
    filters['labels'].present? ? relation.tagged_with(filters['labels'], any: true) : relation
  end

  def row(conversation)
    { label: "##{conversation.display_id}", url: url("conversations/#{conversation.display_id}"),
      values: [conversation.status, conversation.assignee&.name || 'Unassigned', conversation.cached_label_list_array.join(', '),
               conversation.last_activity_at&.to_date] }
  end
end
