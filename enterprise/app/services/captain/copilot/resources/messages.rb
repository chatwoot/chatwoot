class Captain::Copilot::Resources::Messages < Captain::Copilot::Resources::BaseResource
  NAME = 'messages'.freeze
  DATE_FIELDS = %w[created_at].freeze
  # contains uses the trigram index on messages.content, so exact text such as an order number or error code stays fast.
  FILTERS = {
    contains: { type: 'string', minLength: 3, description: 'Text to find. Without since, before or from, searches the last 3 months' },
    sender: { type: 'string', enum: %w[customer agent bot system] }, private: { type: 'boolean' }
  }.freeze
  TEXT_SEARCH_WINDOW = 3.months
  SOURCES = {
    'conversations' => ->(ids) { Message.where(conversation_id: ids) },
    'messages' => ->(ids) { Message.where(id: ids) }
  }.freeze
  COLUMNS = %w[Sender Sent Excerpt].freeze
  PRELOAD = [:conversation].freeze
  GROUPS = %w[sender private].freeze
  EXCERPT_LENGTH = 160
  # The roles of Captain::Copilot::ReviewService.sender_role, computed by the database for filters and counts.
  SENDER_ROLE = Arel.sql("CASE WHEN messages.sender_type = 'Contact' THEN 'customer' WHEN messages.sender_type = 'User' THEN 'agent' " \
                         "WHEN messages.sender_type IS NULL THEN 'system' ELSE 'bot' END")

  # Searching the text of every message an account has is slow when the text is common, so like the dashboard's message
  # search, contains covers the last 3 months unless dates are given. A selection from a saved set is already small and
  # keeps every date.
  def normalize(filters, source: nil)
    filters = super(filters)
    return filters if source || filters['contains'].blank? || filters.key?('since') || filters.key?('before')

    filters.merge('since' => TEXT_SEARCH_WINDOW.ago.iso8601)
  end

  # Customer and agent messages in conversations the user can open. Activity and template messages, and emails an agent
  # forwarded elsewhere, are left out.
  def scope
    @account.messages.where(conversation_id: accessible_conversations(account: @account, user: @user).select(:id),
                            message_type: %w[incoming outgoing]).not_forwarded
  end

  def filter(relation, filters)
    relation = relation.where("#{SENDER_ROLE} = ?", filters['sender']) if filters['sender']
    relation = relation.where(private: filters['private']) unless filters['private'].nil?
    return relation if filters['contains'].blank?

    relation.where('messages.content ILIKE ?', "%#{Message.sanitize_sql_like(filters['contains'])}%")
  end

  def counts_by(relation, group)
    return column_counts(relation, :private) if group == 'private'

    relation.group(SENDER_ROLE).count
  end

  def row(message)
    display_id = message.conversation.display_id
    { label: "##{display_id}", url: url("conversations/#{display_id}"),
      values: [Captain::Copilot::ReviewService.sender_role(message), message.created_at.to_date, message.content.to_s.squish.first(EXCERPT_LENGTH)] }
  end
end
