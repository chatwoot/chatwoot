class Telegram::SendAttachmentsService
  pattr_initialize [:message!]

  def perform
    telegram_attachments = []
    message.attachments.each do |attachment|
      telegram_attachment = {}
      telegram_attachment[:type] = attachment_type(attachment[:file_type])
      telegram_attachment[:media] = attachment.download_url
      telegram_attachments << telegram_attachment
    end

    response = media_group_request(channel.chat_id(message), telegram_attachments, channel.reply_to_message_id(message))
    channel.process_error(message, response)
    response.parsed_response['result'].first['message_id'] if response.success?
  end

  private

  def attachment_type(file_type)
    file_type_mappings = {
      'audio' => 'audio',
      'image' => 'photo',
      'file' => 'document',
      'video' => 'video'
    }
    file_type_mappings[file_type]
  end

  def media_group_request(chat_id, attachments, reply_to_message_id)
    HTTParty.post("#{channel.telegram_api_url}/sendMediaGroup",
                  body: {
                    chat_id: chat_id,
                    media: attachments.to_json,
                    reply_to_message_id: reply_to_message_id
                  })
  end

  def document_request(chat_id, attachment, reply_to_message_id)
    HTTParty.post("#{channel.telegram_api_url}/sendDocument",
                  body: {
                    chat_id: chat_id,
                    document: attachment,
                    reply_to_message_id: reply_to_message_id
                  })
  end

  def channel
    @channel ||= message.inbox.channel
  end
end
