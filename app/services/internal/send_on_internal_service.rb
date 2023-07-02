class Internal::SendOnInternalService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Internal
  end

  def perform_reply
    return if message.message_type == :outgoing

    set_conversation

    return unless @conversation

    puts "message #{message.to_json}"
    puts "@contact_inbox #{@contact_inbox.to_json}"
    puts "@conversation #{@conversation.to_json}"

    reply = @conversation.messages.build(
      content: message.content,
      account_id: message.conversation.inbox.account_id,
      inbox_id: message.conversation.inbox.id,
      message_type: :incoming,
      sender_id: @contact_inbox.contact_id,
      sender_type: 'Contact',
      source_id: message.id,
      attachments: message.attachments
    )
    reply.save!
    message.update!(source_id: reply.id) if reply.id?
  end

  def set_conversation
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: message.sender.email,
      inbox: message.conversation.inbox,
      contact_attributes: contact_params
    ).perform

    @conversation = contact_inbox.conversations.last
    return if @conversation

    user = User.joins(:account_users).where(email: message.conversation.contact_inbox.contact.email,
                                            account_users: { account_id: message.conversation.inbox.account_id }).first
    return unless user

    @conversation = ::Conversation.create!(
      {
        account_id: message.conversation.inbox.account_id,
        inbox_id: message.conversation.inbox.id,
        contact_id: message.sender.id,
        contact_inbox_id: contact_inbox.id,
        assignee_id: user.id
      }
    )
  end

  def contact_params
    { name: message.sender.name, email: message.sender.email }
  end
end
