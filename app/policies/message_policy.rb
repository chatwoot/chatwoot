class MessagePolicy < ApplicationPolicy
  def forward?
    # Check if inbox is email type
    return false unless @record.conversation.inbox.inbox_type == 'Email'

    # Check if message type is forwardable
    return false unless @record.incoming? || @record.outgoing?

    # Check if user has access to the conversation
    ConversationPolicy.new(@user_context, @record.conversation).show?
  end
end
