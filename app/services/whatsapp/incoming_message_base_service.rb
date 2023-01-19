# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  include ::Whatsapp::IncomingMessageServiceHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    processed_params

    if processed_params[:statuses].present?
      process_statuses
    elsif processed_params[:messages].present?
      process_messages
    end
  end

  private

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = Message.find_by(source_id: source_id)
  end

  def process_messages
    # message allready exists so we don't need to process
    return if find_message_by_source_id(@processed_params[:messages].first[:id])

    set_contact
    return unless @contact

    set_conversation
    create_messages
  end

  def process_statuses
    return unless find_message_by_source_id(@processed_params[:statuses].first[:id])

    update_message_with_status(@message, @processed_params[:statuses].first)
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
  end

  def update_message_with_status(message, status)
    message.status = status[:status]
    if status[:status] == 'failed' && status[:errors].present?
      error = status[:errors]&.first
      message.external_error = "#{error[:code]}: #{error[:title]}"
    end
    message.save!
  end

  def create_messages
    return if unprocessable_message_type?(message_type)

    @message = @conversation.messages.build(
      content: message_content(@processed_params[:messages].first),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: @processed_params[:messages].first[:id].to_s
    )
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def processed_params
    @processed_params ||= params
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) || message.dig(:button, :text) || message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title)
  end

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: contact_params[:wa_id],
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{@processed_params[:messages].first[:from]}" }
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
    @conversation = @contact_inbox.conversations.last
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def message_type
    @processed_params[:messages].first[:type]
  end

  def attach_files
    return if %w[text button interactive location].include?(message_type)

    attachment_payload = @processed_params[:messages].first[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def attach_location
    location = @processed_params[:messages].first['location']
    location_name = location['name'] ? "#{location['name']}, #{location['address']}" : ''
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude'],
      fallback_title: location_name,
      external_url: location['url']
    )
  end
end
