class Conversations::ReplyService
  def initialize(conversation)
    @conversation = conversation
  end

  def can_reply?
    channel = @conversation.inbox&.channel

    return can_reply_on_instagram_via_messenger? if instagram_via_messenger?
    return can_reply_on_instagram? if @conversation.inbox.instagram_direct?
    return true unless channel&.messaging_window_enabled?

    last_message_in_messaging_window?(messaging_window)
  end

  private

  def messaging_window
    @conversation.inbox.api? ? @conversation.inbox.channel.additional_attributes['agent_reply_time_window'].to_i : 24
  end

  def last_message_in_messaging_window?(time)
    return false if last_incoming_message.nil?

    Time.current < last_incoming_message.created_at + time.hours
  end

  def instagram_via_messenger?
    @conversation.additional_attributes['type'] == 'instagram_direct_message'
  end

  def can_reply_on_instagram_via_messenger?
    global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')

    return false if last_incoming_message.nil?

    if global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']
      Time.current < last_incoming_message.created_at + 7.days
    else
      last_message_in_messaging_window?(24)
    end
  end

  def can_reply_on_instagram?
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return false if last_incoming_message.nil?

    if global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
      Time.current < last_incoming_message.created_at + 7.days
    else
      last_message_in_messaging_window?(24)
    end
  end

  def last_incoming_message
    @conversation.messages&.incoming&.last
  end
end
