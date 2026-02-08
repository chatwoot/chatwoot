# ref : https://developers.line.biz/en/docs/messaging-api/receiving-messages/#webhook-event-types
# https://developers.line.biz/en/reference/messaging-api/#message-event

class Line::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]
  LINE_STICKER_IMAGE_URL = 'https://stickershop.line-scdn.net/stickershop/v1/sticker/%s/android/sticker.png'.freeze

  def perform
    # probably test events
    return if params[:events].blank?

    line_contact_info
    return if line_contact_info['userId'].blank?

    set_contact
    set_conversation
    parse_events
  end

  private

  def parse_events
    params[:events].each do |event|
      next unless message_created? event

      attach_files event['message']
      @message.save!
    end
  end

  def message_created?(event)
    return unless event_type_message?(event)

    @message = @conversation.messages.build(
      content: message_content(event),
      account_id: @inbox.account_id,
      content_type: message_content_type(event),
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: event['message']['id'].to_s
    )
    @message
  end

  def message_content(event)
    message_type = event.dig('message', 'type')
    case message_type
    when 'text'
      event.dig('message', 'text')
    when 'sticker'
      sticker_id = event.dig('message', 'stickerId')
      sticker_image_url(sticker_id)
    end
  end

  # Currently, Chatwoot doesn't support stickers. As a temporary solution,
  # we're displaying stickers as images using the sticker ID in markdown format.
  # This is subject to change in the future. We've chosen not to download and display the sticker as an image because the sticker's information
  # and images are the property of the creator or legal owner. We aim to avoid storing it on our server without their consent.
  # If there are any permission or rendering issues, the URL may break, and we'll display the sticker ID as text instead.
  # Ref: https://developers.line.biz/en/reference/messaging-api/#wh-sticker
  def sticker_image_url(sticker_id)
    "![sticker-#{sticker_id}](#{LINE_STICKER_IMAGE_URL % sticker_id})"
  end

  def message_content_type(event)
    return 'sticker' if event['message']['type'] == 'sticker'

    'text'
  end

  def attach_files(message)
    return unless message_type_non_text?(message['type'])

    response = inbox.channel.client.get_message_content(message['id'])

    file_name = "media-#{message['id']}.#{response.content_type.split('/')[1]}"
    temp_file = Tempfile.new(file_name)
    temp_file.binmode
    temp_file << response.body
    temp_file.rewind

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(response),
      file: {
        io: temp_file,
        filename: file_name,
        content_type: response.content_type
      }
    )
  end

  def event_type_message?(event)
    event['type'] == 'message' || event['type'] == 'sticker'
  end

  def message_type_non_text?(type)
    [Line::Bot::Event::MessageType::Video, Line::Bot::Event::MessageType::Audio, Line::Bot::Event::MessageType::Image].include?(type)
  end

  def account
    @account ||= inbox.account
  end

  def line_contact_info
    @line_contact_info ||= JSON.parse(inbox.channel.client.get_profile(params[:events].first['source']['userId']).body)
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: line_contact_info['userId'],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: line_contact_info['displayName'],
      avatar_url: line_contact_info['pictureUrl'],
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      social_line_user_id: line_contact_info['userId']
    }
  end

  def file_content_type(file_content)
    file_type(file_content.content_type)
  end
end
