class NotificaMe::SendOnNotificaMeService < Base::SendOnChannelService
  private

  def channel_class
    Channel::NotificaMe
  end

  def perform_reply
    begin
      url = "https://hub.notificame.com.br/v1/channels/#{channel.notifica_me_type}/messages"
      body = message_params.to_json
      Rails.logger.degub("NotificaMe message params #{body}")
      response = HTTParty.post(
        url,
        body: body,
        headers: {
          'X-API-Token' => channel.notifica_me_token,
          'Content-Type' => 'application/json'
        },
        format: :json
      )
      if response.success?
        message.update!(source_id: response.parsed_response["id"])
      else
        raise "Error on send mensagem to NotificaMe: #{response.parsed_response}"
      end
    rescue StandardError => e
      Rails.logger.degub("Error on send do NotificaMe")
      Rails.logger.error(e)
      message.update!(status: :failed, external_error: e.message)
    end
  end

  def message_params
    contents = message.attachments.length > 0 ? message_params_media : message_params_text
    {
      from: channel.notifica_me_id,
      to: contact_inbox.source_id,
      contents: contents
    }
  end

  def message_params_text
    [
      {
        type: :text,
        text: message.content
      }
    ]
  end

  def message_params_media
    message.attachments.map { |a|
      file_type = file_type(a)
      data = {
        type: :file,
        fileMimeType: file_type,
        fileUrl: a.download_url
      }
    }
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def file_type(attachment)
    if attachment.file_type == 'image'
      return 'photo' if channel.notifica_me_type == 'telegram'
    elsif attachment.file_type == 'file'
      extension = extension(attachment.download_url)
      if ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'csv', 'txt'].include?(extension)
        return 'document'
      elsif attachment.file_type == 'file' && ['mov', 'mp4'].include?(extension)
        return 'video'
      elsif attachment.file_type == 'file' && ['ogg', 'mp3', 'wav'].include?(extension)
        return 'audio'
      end
    end
    return attachment.file_type
  end

  def extension(url)
    split = url.split('.')
    split[split.length - 1]
  end
end
