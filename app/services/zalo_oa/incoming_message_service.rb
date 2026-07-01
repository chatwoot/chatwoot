class ZaloOa::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless valid_event?

    process_message_event
  end

  private

  def valid_event?
    params[:event].present? && params[:oa_id].present?
  end

  def process_message_event
    event = params[:event]
    event_type = event[:event_name]

    case event_type
    when 'user_send_text'
      process_text_message(event)
    when 'user_send_image', 'user_send_file', 'user_send_video', 'user_send_audio'
      process_attachment_message(event)
    else
      Rails.logger.info "Unhandled Zalo event type: #{event_type}"
    end
  end

  def process_text_message(event)
    sender_id = event.dig(:sender, :id)
    message_text = event.dig(:message, :text)
    message_id = event.dig(:message, :msg_id)

    return unless sender_id && message_text

    set_contact(sender_id)
    set_conversation

    @message = @conversation.messages.build(
      content: message_text,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message_id.to_s
    )
    @message.save!
  end

  def process_attachment_message(event)
    sender_id = event.dig(:sender, :id)
    message_id = event.dig(:message, :msg_id)
    attachment_info = event.dig(:message, :attachments, 0)

    return unless sender_id && attachment_info

    set_contact(sender_id)
    set_conversation

    attachment_url = attachment_info[:url] || attachment_info[:payload]&.dig(:url)
    attachment_type = determine_attachment_type(event[:event_name])

    @message = @conversation.messages.build(
      content: attachment_info[:name] || attachment_type,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message_id.to_s
    )

    attach_file(attachment_url, attachment_type) if attachment_url
    @message.save!
  end

  def attach_file(url, file_type)
    return unless url

    temp_file = download_file(url)
    return unless temp_file

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type,
      file: {
        io: temp_file,
        filename: File.basename(url),
        content_type: content_type_for(file_type)
      }
    )
  ensure
    temp_file&.close
    temp_file&.unlink
  end

  def download_file(url)
    response = HTTParty.get(url)
    return unless response.success?

    temp_file = Tempfile.new(['zalo_attachment', File.extname(url)])
    temp_file.binmode
    temp_file << response.body
    temp_file.rewind
    temp_file
  rescue StandardError => e
    Rails.logger.error "Failed to download Zalo attachment: #{e.message}"
    nil
  end

  def determine_attachment_type(event_name)
    case event_name
    when 'user_send_image'
      'image'
    when 'user_send_video'
      'video'
    when 'user_send_audio'
      'audio'
    else
      'file'
    end
  end

  def content_type_for(file_type)
    case file_type
    when 'image'
      'image/jpeg'
    when 'video'
      'video/mp4'
    when 'audio'
      'audio/mpeg'
    else
      'application/octet-stream'
    end
  end

  def set_contact(user_id)
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: user_id.to_s,
      inbox: inbox,
      contact_attributes: contact_attributes(user_id)
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        zalo_user_id: @contact_inbox.source_id
      }
    }
  end

  def contact_attributes(user_id)
    {
      name: params.dig(:event, :sender, :name) || "Zalo User #{user_id}",
      additional_attributes: {
        zalo_user_id: user_id.to_s
      }
    }
  end
end
