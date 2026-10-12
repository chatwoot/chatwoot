class Captain::Copilot::Resources::Messages < Captain::Copilot::Resources::BaseResource
  NAME = 'messages'.freeze
  DATE_FIELDS = %w[created_at].freeze
  # contains uses the trigram index on messages.content, so exact text such as an order number or error code stays fast.
  FILTERS = {
    contains: { type: 'string', minLength: 3 }, sender: { type: 'string', enum: %w[customer agent] }, private: { type: 'boolean' }
  }.freeze
  SOURCES = {
    'conversations' => ->(ids) { Message.where(conversation_id: ids) }
  }.freeze
  COLUMNS = %w[Sender Sent Excerpt].freeze
  PRELOAD = [:conversation].freeze
  GROUPS = %w[sender private].freeze
  EXCERPT_LENGTH = 160

  # Customer and agent messages in conversations the user can open. Activity and template messages are left out.
  def scope
    @account.messages.where(conversation_id: accessible_conversations(account: @account, user: @user).select(:id),
                            message_type: %w[incoming outgoing])
  end

  def filter(relation, filters)
    relation = relation.where(message_type: filters['sender'] == 'customer' ? 'incoming' : 'outgoing') if filters['sender']
    relation = relation.where(private: filters['private']) unless filters['private'].nil?
    return relation if filters['contains'].blank?

    relation.where('messages.content ILIKE ?', "%#{Message.sanitize_sql_like(filters['contains'])}%")
  end

  def counts_by(relation, group)
    return column_counts(relation, :private, none: 'Unknown') if group == 'private'

    column_counts(relation, :message_type, none: 'Unknown').transform_keys { |type| type == 'incoming' ? 'customer' : 'agent' }
  end

  def row(message)
    display_id = message.conversation.display_id
    { label: "##{display_id}", url: url("conversations/#{display_id}"),
      values: [message.incoming? ? 'customer' : 'agent', message.created_at.to_date, message.content.to_s.squish.first(EXCERPT_LENGTH)] }
  end
end
