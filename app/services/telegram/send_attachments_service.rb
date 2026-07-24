require 'faraday/multipart'

# Telegram Attachment APIs: ref: https://core.telegram.org/bots/api#inputfile

# Media attachments like photos, videos can be clubbed together and sent as a media group
# Audio can be clubbed together and send as a media group, but can't be mixed with other types
# Documents are sent individually

# We are using `HTTP URL` to send media attachments, telegram will directly download the media from the URL and send it to the user.
# But for documents, we need to send the file as a multipart request. as telegram only support pdf and zip for the download from the URL option.

# ref: `In sendDocument, sending by URL will currently only work for GIF, PDF and ZIP files.`
# ref: `https://core.telegram.org/bots/api#senddocument`
# ref: `https://core.telegram.org/bots/api#sendmediaGroup

# The service will terminate if any of the attachment requests fail when the message has multiple attachments
# We will create multiple messages in telegram if the message has multiple attachments (if its documents or mixed media).
class Telegram::SendAttachmentsService
  pattr_initialize [:message!]

  def perform
    attachment_message_id = nil

    group_attachments_by_type.each do |type, attachments|
      attachment_message_id = process_attachments_by_type(type, attachments)
      break if attachment_message_id.nil?
    end

    attachment_message_id
  end

  private

  def process_attachments_by_type(type, attachments)
    response = send_attachments(type, attachments)
    return extract_attachment_message_id(response) if handle_response(response)

    nil
  end

  def send_attachments(type, attachments)
    if [:media, :audio].include?(type)
      media_group_request(channel.chat_id(message), attachments, channel.reply_to_message_id(message))
    else
      send_individual_attachments(attachments)
    end
  end

  def group_attachments_by_type
    attachments_by_type = { media: [], audio: [], document: [] }

    message.attachments.each do |attachment|
      type = attachment_type(attachment[:file_type])
      attachment_data = { type: type, media: attachment.download_url, attachment: attachment }
      case type
      when 'document'
        attachments_by_type[:document] << attachment_data
      when 'audio'
        attachments_by_type[:audio] << attachment_data
      when 'photo', 'video'
        attachments_by_type[:media] << attachment_data
      end
    end

    attachments_by_type.reject { |_, v| v.empty? }
  end

  def attachment_type(file_type)
    { 'audio' => 'audio', 'image' => 'photo', 'file' => 'document', 'video' => 'video' }[file_type] || 'document'
  end

  def media_group_request(chat_id, attachments, reply_to_message_id)
    HTTParty.post("#{channel.telegram_api_url}/sendMediaGroup",
                  body: {
                    chat_id: chat_id,
                    **business_connection_body,
                    media: attachments.map { |hash| hash.except(:attachment) }.to_json,
                    reply_to_message_id: reply_to_message_id
                  })
  end

  def send_individual_attachments(attachments)
    response = nil
    attachments.map do |attachment|
      response = document_request(channel.chat_id(message), attachment, channel.reply_to_message_id(message))
      break unless handle_response(response)
    end
    response
  end

  def document_request(chat_id, attachment, reply_to_message_id)
    temp_file_path = save_attachment_to_tempfile(attachment[:attachment])
    response = send_file(chat_id, temp_file_path, reply_to_message_id)
    File.delete(temp_file_path)
    response
  end

  # Telegram picks up the file name from original field name, so we need to save the file with the original name.
  # Hence not using Tempfile here.
  def save_attachment_to_tempfile(attachment)
    temp_dir = Rails.root.join('tmp/uploads', "telegram-#{attachment.message_id}")
    FileUtils.mkdir_p(temp_dir)
    temp_file_path = File.join(temp_dir, attachment.file.filename.to_s)

    File.open(temp_file_path, 'wb') do |file|
      attachment.file.blob.open do |blob_file|
        IO.copy_stream(blob_file, file)
      end
    end

    temp_file_path
  end

  def send_file(chat_id, file_path, reply_to_message_id)
    File.open(file_path, 'rb') do |file|
      file_name = File.basename(file_path)
      mime_type = Marcel::MimeType.for(name: file_name) || 'application/octet-stream'

      payload = { chat_id: chat_id, document: Faraday::Multipart::FilePart.new(file, mime_type, file_name) }
      payload[:reply_to_message_id] = reply_to_message_id if reply_to_message_id
      payload.merge!(business_connection_body)

      response = multipart_post_connection.post("#{channel.telegram_api_url}/sendDocument", payload)
      parse_faraday_response(response)
    end
  end

  def multipart_post_connection
    @multipart_post_connection ||= Faraday.new do |f|
      f.request :multipart
      f.options.timeout = 300
      f.options.open_timeout = 60
    end
  end

  def parse_faraday_response(response)
    parsed = JSON.parse(response.body)
    OpenStruct.new(success?: response.success?, parsed_response: parsed)
  rescue JSON::ParserError
    OpenStruct.new(success?: false, parsed_response: { 'ok' => false, 'error_code' => response.status, 'description' => response.reason_phrase })
  end

  def handle_response(response)
    return true if response.success?

    Rails.logger.error "Message Id: #{message.id}  - Error sending attachment to telegram:  #{response.parsed_response}"
    channel.process_error(message, response)
    false
  end

  def extract_attachment_message_id(response)
    return unless response.success?

    result = response.parsed_response['result']
    # response will be an array if the request for media group
    # response will be a hash if the request for document
    result.is_a?(Array) ? result.first['message_id'] : result['message_id']
  end

  def channel
    @channel ||= message.inbox.channel
  end

  def business_connection_id
    @business_connection_id ||= channel.business_connection_id(message)
  end

  def business_connection_body
    body = {}
    body[:business_connection_id] = business_connection_id if business_connection_id
    body
  end
end
