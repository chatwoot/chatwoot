class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    FacebookBot::Bot.deliver(delivery_params, access_token: message.channel_token)
  end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content }
    }
  end

  def fb_attachment_message_params
    attachment = message.attachments.first
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.file_url
          }
        }
      }
    }
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
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
