class NotificaMe::SendOnNotificaMeService < Base::SendOnChannelService
  private

  def channel_class
    Channel::NotificaMe
  end

  def perform_reply
    begin
      url = "https://hub.notificame.com.br/v1/channels/#{channel.channel_type}/messages"
      response = HTTParty.post(
        url,
        body: message_params.to_json,
        headers: {
          'X-API-Token' => channel.channel_token
        }
      )
      if response.success?
        message.update!(source_id: response.success?, status: :sent)
      else
        raise "Error on send mensagem to NotificaMe: #{response.parsed_response}"
      end
    rescue StandardError => e
      Rails.logger.error("Error on send do notificame")
      Rails.logger.error(e)
      message.update!(status: :failed, external_error: e.message)
    end
  end

  def message_params
    contents = message.message_type == :text ? message_params_text : message_params_media
    {
      from: channel.channel_id,
      to: contact_inbox.source_id,
      contents: contents
    }
  end

  def message_params_text
    {
      type: :text,
      text: message.content
    }
  end

  def message_params_media
    message.attachments.map { |a|
      {
        type: :file,
        fileMimeType: a.message_type,
        fileUrl: a.download_url,
        fileCaption: message.content
      }
    }
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
