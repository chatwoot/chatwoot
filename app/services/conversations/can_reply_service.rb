class Conversations::CanReplyService
  DEFAULT_MESSAGING_WINDOW = 24
  EXTENDED_MESSAGING_WINDOW = 7.days
  INSTAGRAM_MESSENGER_TYPE = 'instagram_direct_message'

  def initialize(conversation)
    @conversation = conversation
  end

  def can_reply?
    return false if last_incoming_message.nil?

    channel = @conversation.inbox&.channel
    return true unless channel&.messaging_window_enabled?

    case channel_type
    when :instagram_messenger
      can_reply_on_instagram_via_messenger?
    when :instagram_direct
      can_reply_on_instagram?
    else
      last_message_in_messaging_window?(messaging_window)
    end
  end

  private

  def channel_type
    return :instagram_messenger if instagram_via_messenger?
    return :instagram_direct if @conversation.inbox.instagram_direct?
    :other
  end

  def messaging_window
    return DEFAULT_MESSAGING_WINDOW unless @conversation.inbox.api?

    window = @conversation.inbox.channel.additional_attributes['agent_reply_time_window'].to_i
    window.positive? ? window : DEFAULT_MESSAGING_WINDOW
  end

  def last_message_in_messaging_window?(time)
    Time.current < last_incoming_message.created_at + time.hours
  end

  def instagram_via_messenger?
    @conversation.additional_attributes['type'] == INSTAGRAM_MESSENGER_TYPE
  end

  def can_reply_on_instagram_via_messenger?
    global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
    extended_window_enabled?(global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT'])
  end

  def can_reply_on_instagram?
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
    extended_window_enabled?(global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT'])
  end

  def extended_window_enabled?(enabled)
    if enabled
      Time.current < last_incoming_message.created_at + EXTENDED_MESSAGING_WINDOW
    else
      last_message_in_messaging_window?(DEFAULT_MESSAGING_WINDOW)
    end
  end

  def last_incoming_message
    @conversation.messages&.incoming&.last
  end
end
