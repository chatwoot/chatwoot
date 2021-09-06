class Instagram::SendOnInstagramService < Base::SendOnChannelService
  include HTTParty

  pattr_initialize [:message!]
  base_uri 'https://graph.facebook.com/v11.0/me'

  private

  delegate :additional_attributes, to: :contact

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    if message.attachments.present?
      send_to_facebook_page merge_attachement_params
    else
      send_to_facebook_page message_params
    end
  rescue Facebook::Messenger::FacebookError => e
    Rails.logger.info e
    channel.authorization_error!
  end

  def message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content
      }
    }
  end

  def merge_attachement_params
    attachment = message.attachments.first
    message_params[:message][:attachment] = {
      type: 'image',
      payload: {
        url: attachment.file_url
      }
    }
    message_params
  end

  # Deliver a message with the given payload.
  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/send-message
  def send_to_facebook_page(message_content)
    access_token = channel.page_access_token
    options = {
      body: message_content
    }
    url = "https://graph.facebook.com/v11.0/me/messages?access_token=#{access_token}"

    response = HTTParty.post(url, options)
    response.body
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def conversation_type
    conversation.additional_attributes['type']
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', last_incoming_message.id).count == 1
  end

  def last_incoming_message
    conversation.messages.incoming.last
  end

  def config
    Facebook::Messenger.config
  end
end
