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

  def account_presence_updated(event)
    account_id, user_id, status = event.data.values_at(:account_id, :user_id, :status)
    account = Account.find(account_id)

    account.inboxes.joins(:inbox_members).where(inbox_members: { user_id: user_id }).find_each do |inbox|
      next unless inbox.channel.respond_to?(:update_presence)

      inbox.channel.update_presence(status)
    end
  end

  private

  def handle_typing_event(event)
    is_private, conversation = event.data.values_at(:is_private, :conversation)
    return if is_private

    channel = conversation.inbox.channel
    return unless channel.respond_to?(:toggle_typing_status)

    channel.toggle_typing_status(event.name, conversation: conversation)
  end
end
