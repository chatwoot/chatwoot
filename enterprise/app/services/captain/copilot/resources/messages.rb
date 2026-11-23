class Captain::Copilot::Resources::Messages < Captain::Copilot::Resources::BaseResource
  NAME = 'messages'.freeze
  MODEL = Message
  DATE_FIELDS = %w[created_at].freeze
  # contains uses the trigram index on messages.content, so exact text such as an order number or error code stays fast.
  # A message's sender is polymorphic, so the sender is filtered by role, and agents by agent_id.
  FILTERS = {
    contains: { type: 'string', minLength: 3,
                description: "Text to find. Without since, before or from, searches the last #{Limits.search_time_range_limit_days} days" },
    sender: { type: 'string', enum: %w[customer agent bot system] },
    agent_id: { type: 'integer', minimum: 1, description: 'Messages this agent sent' }
  }.freeze
  SOURCES = {}.freeze
  COLUMNS = %w[Sender Sent Excerpt].freeze
  PRELOAD = [:conversation].freeze
  GROUPS = %w[sender agent].freeze
  EXCERPT_LENGTH = 160

  # Searching the text of every message an account has is slow when the text is common, so contains covers the same
  # window as the dashboard's message search unless dates are given. A selection from a saved set is already small and
  # keeps every date.
  def normalize(filters, source: nil)
    filters = super(filters)
    return filters if source || filters['contains'].blank? || filters.key?('since') || filters.key?('before')

    since = Limits.search_time_range_limit_days.days.ago
    window = "Only messages sent since #{since.to_date.iso8601} were searched, because no dates were given. Earlier messages were not checked."
    @note = [@note, window].compact.join(' ')
    filters.merge('since' => since.iso8601)
  end

  # The messages Copilot reads, in conversations the user can open.
  def scope
    conversations = accessible_conversations(account: @account, user: @user).select(:id)
    Captain::Copilot::ReadableMessages.scope(@account.messages.where(conversation_id: conversations))
  end

  def filter(relation, filters)
    relation = Captain::Copilot::ReadableMessages.with_role(relation, filters['sender']) if filters['sender']
    relation = relation.where(sender_type: 'User', sender_id: filters['agent_id']) if filters['agent_id']
    return relation if filters['contains'].blank?

    relation.where(Message.arel_table[:content].matches("%#{Message.sanitize_sql_like(filters['contains'])}%"))
  end

  def group_field(name)
    sender_type = Message.arel_table[:sender_type]
    case name
    when 'sender'
      roles = Captain::Copilot::ReadableMessages::ROLES.reduce(Arel::Nodes::Case.new) do |node, (type, role)|
        node.when(sender_type.eq(type)).then(role)
      end
      { expression: roles.when(sender_type.eq(nil)).then('system').else('bot') }
    when 'agent'
      { expression: Arel::Nodes::Case.new.when(sender_type.eq('User')).then(Message.arel_table[:sender_id]), names: User }
    end
  end

  def row(message)
    display_id = message.conversation.display_id
    sender = Captain::Copilot::ReadableMessages.sender_role(message)
    { label: "##{display_id}", url: url("conversations/#{display_id}"),
      values: [sender, message.created_at.to_date, message.content.to_s.squish.first(EXCERPT_LENGTH)] }
  end
end
