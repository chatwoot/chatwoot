class Facebook::SendReplyService
  pattr_initialize [:message!]

  def perform
    return if message.private
    return if inbox.channel.class.to_s != 'Channel::FacebookPage'
    return unless outgoing_message_from_chatwoot?

    Bot.deliver(delivery_params, access_token: message.channel_token)
  end

  private

  delegate :contact, to: :conversation

  def inbox
    @inbox ||= message.inbox
  end

  def conversation
    @conversation ||= message.conversation
  end

  def outgoing_message_from_chatwoot?
    # messages sent directly from chatwoot won't have source_id.
    message.outgoing? && !message.source_id
  end

  # def reopen_lock
  #   if message.incoming? && conversation.locked?
  #     conversation.unlock!
  #   end
  # end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content }
    }
  end

  def fb_attachment_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'image',
          payload: {
            url: message.attachments.first.file_url
          }
        }
      }
    }
  end

  def fb_message_params
    if message.attachments.blank?
      fb_text_message_params
    else
      fb_attachment_message_params
    end
  end

  def delivery_params
    if twenty_four_hour_window_over?
      fb_message_params.merge(tag: 'ISSUE_RESOLUTION')
    else
      fb_message_params
    end
  end

  def twenty_four_hour_window_over?
    return false unless after_24_hours?
    return false if last_incoming_and_outgoing_message_after_one_day?

    true
  end

  def last_incoming_and_outgoing_message_after_one_day?
    last_incoming_message && sent_first_outgoing_message_after_24_hours?
  end

  def after_24_hours?
    (Time.current - last_incoming_message.created_at) / 3600 >= 24
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', last_incoming_message.id).count == 1
  end

  def last_incoming_message
    conversation.messages.incoming.last
  end
end
