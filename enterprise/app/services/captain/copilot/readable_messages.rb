# The messages Copilot reads: customer and agent messages, private notes included. Activity messages, emails an agent
# forwarded elsewhere and deleted messages are left out. Screening, the review model and the messages resource all start
# here, so screening reads the same messages the review model does.
module Captain::Copilot::ReadableMessages
  # A role instead of the sender's class, so a bot's name such as Captain::Assistant is not read as conversation content.
  ROLES = { 'Contact' => 'customer', 'User' => 'agent' }.freeze
  # The same roles computed by the database, for filters and counts.
  ROLE_SQL = Arel.sql("CASE #{ROLES.map { |type, role| "WHEN messages.sender_type = '#{type}' THEN '#{role}'" }.join(' ')} " \
                      "WHEN messages.sender_type IS NULL THEN 'system' ELSE 'bot' END")
  # A deleted message keeps its row with placeholder text, so it would otherwise be read as content.
  NOT_DELETED = Arel.sql("((messages.content_attributes #>> '{}')::jsonb ->> 'deleted') IS DISTINCT FROM 'true'")

  def self.scope(messages, as_of: nil)
    messages = messages.where(message_type: %w[incoming outgoing]).not_forwarded.where(NOT_DELETED)
    as_of ? messages.where(Message.arel_table[:created_at].lteq(as_of)) : messages
  end

  def self.sender_role(message)
    ROLES.fetch(message.sender_type, message.sender_type ? 'bot' : 'system')
  end
end
