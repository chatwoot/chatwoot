# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class CommonWhatsapp::IncomingMessageService
    include ::CommonWhatsapp::IncomingMessageServiceHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    processed_params
    process_messages
  end

  private

  def process_messages
    # message allready exists so we don't need to process
    return if find_message_by_source_id(@processed_params[:id]) || message_under_process?
    
    cache_message_source_id_in_redis
    set_contact
    
    return unless @contact

    set_conversation
    create_messages
    clear_message_source_id_from_redis
  end

  def create_messages
    return if unprocessable_message_type?(message_type)

    process_in_reply_to(@processed_params)

    message_type == 'vcard' || message_type == 'multi_vcard' ? create_contact_messages(@processed_params) : create_regular_message(@processed_params)
  end

  def create_contact_messages(message)
    if message_type == 'vcard'
      create_message(message)
      attach_single_contact(message)
      @message.save!
    else
      message[:vcardList].each do |contact|
        contact_attachment_message(contact[:displayName])
        attach_on_multiple_contacts(contact)
        @message.save!
      end
    end
  end

  def create_regular_message(message)
    create_message(message)
    
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def set_contact
    contact_params = @processed_params[:sender]
    return if contact_params.blank?

    waid = processed_waid(contact_params[:id])

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: contact_params[:name], phone_number: "+#{@processed_params[:from].gsub(/\s+|@.*/, '')}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.last
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def attach_files
    Rails.logger.info("NO ATTACH_FILES")
    return if %w[text video chat button interactive location contacts].include?(message_type)

    attachment_payload = @processed_params
    @message.content = @processed_params[:caption]

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file[:file],
        filename: attachment_file[:file_name],
        content_type: attachment_file[:file_type]
      }
    )
  end

  def attach_location
    location = @processed_params
    location_name = ''
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location[:lat],
      coordinates_long: location[:lng],
      fallback_title: location_name,
      external_url: ''
    )
  end

  def create_message(message)
    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      in_reply_to_external_id: @in_reply_to_external_id,
      in_reply_to: @in_reply_to
    )
  end

  def attach_single_contact(message)
    phone = message[:body].scan(/waid=(\d+)/).flatten.first
    phone.prepend('+') unless phone.start_with?('+')
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      fallback_title: phone.to_s
    )
  end

  def attach_on_multiple_contacts(contact)
    phone = contact[:vcard].scan(/waid=(\d+)/).flatten.first
    phone.prepend('+') unless phone.start_with?('+')
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      fallback_title: phone.to_s
    )
  end

  def contact_attachment_message(content)
    @message = @conversation.messages.build(
      content: content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: nil,
      in_reply_to_external_id: @in_reply_to_external_id,
      in_reply_to: @in_reply_to
    )
  end
end
