module Whatsapp::IncomingContactMessageHandler
  def create_contact_messages(message)
    message = process_contact_info_response(message)
    Array(message[:contacts]).each do |contact|
      # Pass source_id from parent message since contact objects don't have :id
      create_message(contact, source_id: message[:id], content_attributes_source: message)
      attach_contact(contact, contact_info_response_handled: message[:contact_info_response_handled])
      @message.save!
    end
  end

  def process_contact_info_response(message)
    contact_params = @processed_params[:contacts]&.first || {}
    response_payload = message.merge(
      from_user_id: message[:from_user_id].presence || contact_params[:user_id],
      from_parent_user_id: message[:from_parent_user_id].presence || contact_params[:parent_user_id]
    )
    handled_state = Whatsapp::ContactInfoResponseService.new(
      contact_inbox: @contact_inbox, message_payload: response_payload
    ).perform

    message.merge(contact_info_response_handled: handled_state == 'shared')
  end

  def attach_contact(contact, contact_info_response_handled: false)
    phones = contact[:phones].presence || [{ phone: 'Phone number is not available' }]

    name_info = contact['name'] || {}
    contact_meta = {
      firstName: name_info['first_name'],
      lastName: name_info['last_name']
    }.compact
    contact_meta[:isContactInfoResponse] = true if contact_info_response_handled

    phones.each do |phone|
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(message_type),
        fallback_title: phone[:phone].to_s,
        meta: contact_meta
      )
    end
  end
end
