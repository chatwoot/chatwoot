# The messages Copilot reads: customer and agent messages, private notes included. Activity messages, emails an agent
# forwarded elsewhere and deleted messages are left out. Screening, the review model and the messages resource all start
# here, so screening reads the same messages the review model does.
module Captain::Copilot::ReadableMessages
  # A role instead of the sender's class, so a bot's name such as Captain::Assistant is not read as conversation content.
  ROLES = { 'Contact' => 'customer', 'User' => 'agent' }.freeze
  def self.scope(messages, as_of: nil)
    messages = messages.where(message_type: %w[incoming outgoing]).not_forwarded.not_deleted
    as_of ? messages.where(Message.arel_table[:created_at].lteq(as_of)) : messages
  end

  def self.role_for(sender_type)
    ROLES.fetch(sender_type) { sender_type ? 'bot' : 'system' }
  end

  def self.sender_role(message)
    role_for(message.sender_type)
  end

  # The messages a role sent, for the sender filter.
  def self.with_role(messages, role)
    case role
    when 'system' then messages.where(sender_type: nil)
    when 'bot' then messages.where.not(sender_type: [*ROLES.keys, nil])
    else messages.where(sender_type: ROLES.key(role))
    end
  end
end
