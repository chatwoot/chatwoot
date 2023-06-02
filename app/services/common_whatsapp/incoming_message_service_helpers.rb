module CommonWhatsapp::IncomingMessageServiceHelpers
  require 'base64'
  
  def download_attachment_file(attachment_payload)
    decoded_file = Base64.decode64(attachment_payload[:body])
    file_name = "media-#{attachment_payload[:mediaKeyTimestamp]}.#{attachment_payload[:mimetype].split('/')[1]}"
    file = Tempfile.new(file_name)
    file.binmode
    file << decoded_file
    file.rewind
    
    { file: file, file_type: attachment_payload[:mimetype], file_name: file_name }
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    @processed_params[:type]
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    return '' if message_type_is_b64?(message_type)
    message[:body]
      # message[:body] ||
      # message.dig(:button, :text) ||
      # message.dig(:interactive, :button_reply, :title) ||
      # message.dig(:interactive, :list_reply, :title) ||
      # message.dig(:name, :formatted_name)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[sticker poll_creation vcard location ephemeral unsupported].include?(message_type)
  end

  def message_type_is_b64?(message_type)
    %w[document location image ptt audio].include?(message_type)
  end

  def brazil_phone_number?(phone_number)
    phone_number.match(/^55/)
  end

  # ref: https://github.com/chatwoot/chatwoot/issues/5840
  def normalised_brazil_mobile_number(phone_number)
    # DDD : Area codes in Brazil are popularly known as "DDD codes" (códigos DDD) or simply "DDD", from the initials of "direct distance dialing"
    # https://en.wikipedia.org/wiki/Telephone_numbers_in_Brazil
    ddd = phone_number[2, 2]
    # Remove country code and DDD to obtain the number
    number = phone_number[4, phone_number.length - 4]
    normalised_number = "55#{ddd}#{number}"
    # insert 9 to convert the number to the new mobile number format
    normalised_number = "55#{ddd}9#{number}" if normalised_number.length != 13
    normalised_number
  end

  def processed_waid(waid)
    # in case of Brazil, we need to do additional processing
    # https://github.com/chatwoot/chatwoot/issues/5840
    if brazil_phone_number?(waid)
      # check if there is an existing contact inbox with the normalised waid
      # We will create conversation against it
      contact_inbox = inbox.contact_inboxes.find_by(source_id: normalised_brazil_mobile_number(waid))

      # if there is no contact inbox with the waid without 9,
      # We will create contact inboxes and contacts with the number 9 added
      waid = contact_inbox.source_id if contact_inbox.present?
    end
    waid
  end

  def process_in_reply_to(message)
    return if message['quotedMsgId'].blank?

    @in_reply_to_external_id = message['quotedMsgId']

    return if @in_reply_to_external_id.blank?

    in_reply_to_message = Message.find_by(source_id: @in_reply_to_external_id)

    @in_reply_to = in_reply_to_message.id if in_reply_to_message.present?
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = Message.find_by(source_id: source_id)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:id])
    Redis::Alfred.get(key)
  end

  def cache_message_source_id_in_redis
    return if @processed_params.try(:[], :body).blank?

    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:id])
    ::Redis::Alfred.setex(key, true)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:id])
    ::Redis::Alfred.delete(key)
  end
end
