# ref : https://developers.line.biz/en/docs/messaging-api/receiving-messages/#webhook-event-types
# https://developers.line.biz/en/reference/messaging-api/#message-event

class Line::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]
  LINE_STICKER_IMAGE_URL = 'https://stickershop.line-scdn.net/stickershop/v1/sticker/%s/android/sticker.png'.freeze

  def perform
    return if params[:events].blank?

    params[:events].each { |event| process_event_safely(event) }
  end

  private

  def process_event_safely(event)
    process_event(event)
  rescue Line::ContactResolverService::AmbiguousContactMatchError => e
    Rails.logger.warn(
      '[LINE] Skipping incoming message event due to ambiguous contact match ' \
      "inbox_id=#{inbox.id} line_user_id=#{event.dig('source', 'userId')} " \
      "line_message_id=#{event.dig('message', 'id')} error=#{e.message}"
    )
  end

  def process_event(event)
    return unless event_type_message?(event)
    return if duplicate_message?(event)

    profile = fetch_profile(event)
    return if profile.blank? || profile.user_id.blank?

    @contact_inbox = Line::ContactResolverService.new(inbox: inbox, profile: profile).perform
    @contact = @contact_inbox.contact
    @conversation = find_or_create_conversation
    @message = build_message(event)

    attach_files(event['message'])
    @message.save!
  end

  def duplicate_message?(event)
    inbox.messages.exists?(source_id: event.dig('message', 'id').to_s)
  end

  def fetch_profile(event)
    inbox.channel.messaging_api_client.get_profile(user_id: event.dig('source', 'userId'))
  end

  def build_message(event)
    @conversation.messages.build(
      content: message_content(event),
      account_id: inbox.account_id,
      content_type: message_content_type(event),
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: event.dig('message', 'id').to_s
    )
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
    return unless %w[video audio image file].include?(message['type'])

    body, status, headers = media_content(message['id'])
    return unless status == 200

    content_type = headers['content-type']
    file_name = attachment_file_name(message, content_type)
    temp_file = build_temp_file(file_name, body)

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(content_type),
      file: {
        io: temp_file,
        filename: file_name,
        content_type: content_type
      }
    )
  end

  def media_content(message_id)
    inbox.channel.messaging_api_blob_client.get_message_content_with_http_info(message_id: message_id)
  end

  def attachment_file_name(message, content_type)
    extension = content_type&.split('/')&.last || 'bin'
    message['fileName'] || "media-#{message['id']}.#{extension}"
  end

  def build_temp_file(file_name, body)
    temp_file = Tempfile.new(file_name)
    temp_file.binmode
    temp_file << body
    temp_file.rewind
    temp_file
  end

  def event_type_message?(event)
    event['type'] == 'message'
  end

  def find_or_create_conversation
    conversation = if inbox.lock_to_single_conversation
                     @contact_inbox.conversations.last
                   else
                     @contact_inbox.conversations.where.not(status: :resolved).last
                   end

    conversation || Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end
end
