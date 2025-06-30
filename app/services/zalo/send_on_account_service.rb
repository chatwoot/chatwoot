class Zalo::SendOnAccountService < Base::SendOnChannelService
  SUPPORTED_TYPES = %w[image video audio file]
  SUPPORTED_FILE_EXTENSIONS = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
    text/csv
  ]

  private

  def channel_class
    Channel::Zalo
  end

  def perform_reply
    upload_attachments
    send_text_message
    send_attachments
    Messages::StatusUpdateService.new(message, 'delivered').perform
  rescue Integrations::Zalo::Client::AuthError => e
    Messages::StatusUpdateService.new(message, 'failed', 'Authorization error').perform
    channel.authorization_error!
    channel.refresh_access_token!
  rescue StandardError => e
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
    Rails.logger.info "Zalo::SendOnAccountService: Error sending message to Zalo Account - #{channel.oa_id}: #{e.message}"
  end

  def upload_attachments
    @attachment_links = []
    message.attachments.each do |attachment|
      next if attachment.download_url.blank?
      next if attachment.meta.to_h['zalo_file_data'].present?
      next if SUPPORTED_TYPES.exclude?(attachment.file_type)

      case attachment.file.attachment.blob.content_type
      when 'image/gif'
        upload_response = zalo_uploader.upload_gif(attachment.download_url)
      when 'image/jpeg', 'image/png'
        upload_response = zalo_uploader.upload_image(attachment.download_url)
      when *SUPPORTED_FILE_EXTENSIONS
        upload_response = zalo_uploader.upload_file(attachment.download_url)
      else # video, audio, or unsupported file types
        @attachment_links << attachment.download_url
      end
      if upload_response.present?
        attachment.meta['zalo_file_data'] = upload_response
        attachment.save!
      end
    end
  end

  def send_text_message
    message_content = [message.content.presence, @attachment_links].flatten.compact.join("\n")
    return if message_content.blank?
    response = message_caller.send_message(zalo_id, message_content)
    message.update!(source_id: response.dig('message_id'))
  end

  def send_attachments
    message.attachments.each do |attachment|
      if attachment.meta.dig('zalo_file_data', 'token').present?
        payload = {
          type: :file,
          payload: {
            token: attachment.meta.dig('zalo_file_data', 'token'),
          },
        }
      elsif attachment.meta.dig('zalo_file_data', 'attachment_id').present?
        payload = {
          type: :template,
          payload: {
            template_type: :media,
            elements: [{
              media_type: :gif,
              attachment_id: attachment.meta.dig('zalo_file_data', 'attachment_id'),
              width: attachment.file.attachment&.blob&.metadata&.dig('width') || 100,
              height: attachment.file.attachment&.blob&.metadata&.dig('height') || 100,
            }],
          },
        }
      elsif attachment.file_type == 'image'
        payload = {
          type: :template,
          payload: {
            template_type: :media,
            elements: [{
              media_type: :image,
              url: attachment.download_url,
            }]
          },
        }
      end

      if payload
        response = message_caller.send_attachment(zalo_id, payload)
        attachment.update!(external_code: response.dig('message_id'))
      end
    end
  end

  def message_caller
    @message_caller ||= Integrations::Zalo::Message.new(channel.access_token)
  end

  def zalo_uploader
    @zalo_uploader ||= Integrations::Zalo::Uploader.new(channel.access_token)
  end

  def zalo_id
    @zalo_id ||= contact_inbox.source_id.to_i
  end

end
