class ChannelListener < BaseListener
  def conversation_typing_on(event)
    handle_typing_event(event)
  end

  def conversation_recording(event)
    handle_typing_event(event)
  end

  def conversation_typing_off(event)
    handle_typing_event(event)
  end

  def conversation_unread(event)
    conversation = event.data[:conversation]
    channel = conversation.inbox.channel
    return unless channel.respond_to?(:unread_conversation)

    channel.unread_conversation(conversation)
  end

  def account_presence_updated(event)
    account_id, user_id, status = event.data.values_at(:account_id, :user_id, :status)
    account = Account.find(account_id)

    account.inboxes.joins(:inbox_members).where(inbox_members: { user_id: user_id }).find_each do |inbox|
      next unless inbox.channel.respond_to?(:update_presence)

      inbox.channel.update_presence(status)
    end
  end

  # Two callers, two ways of naming the messages. A person opening the thread has only a
  # watermark to go on, so the set is everything inbound since it. An agent bot names the
  # messages it processed, and those ids win: the bot is answering a specific turn, not
  # catching up on a thread, and it has no watermark of its own to widen the set with.
  def messages_read(event)
    conversation, last_seen_at, message_ids = event.data.values_at(:conversation, :last_seen_at, :message_ids)

    channel = conversation.inbox.channel
    return unless channel.respond_to?(:read_messages)

    messages = conversation.messages.where(message_type: :incoming).where.not(status: :read)

    messages = if message_ids.present?
                 messages.where(id: message_ids)
               elsif last_seen_at.present?
                 messages.where('updated_at > ?', last_seen_at)
               else
                 messages
               end

    channel.read_messages(messages, conversation: conversation) if messages.any?
  end

  private

  def handle_typing_event(event)
    is_private, conversation, user = event.data.values_at(:is_private, :conversation, :user)
    return if is_private
    return if user.is_a?(Contact)

    channel = conversation.inbox.channel
    return unless channel.respond_to?(:toggle_typing_status)

    channel.toggle_typing_status(event.name, conversation: conversation)
  end
end
