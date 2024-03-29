class NotificaMe::SendOnNotificaMeService < Base::SendOnChannelService
  private

  def channel_class
    Channel::NotificaMe
  end

  def perform_reply
    begin
      url = "https://hub.notificame.com.br/v1/channels/#{channel.notifica_me_type}/messages"
      body = message_params.to_json
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
        message.update!(source_id: response.parsed_response["id"], status: :sent)
      else
        raise "Error on send mensagem to NotificaMe: #{response.parsed_response}"
      end
    rescue StandardError => e
      Rails.logger.error("Error on send do NotificaMe")
      Rails.logger.error(e)
      message.update!(status: :failed, external_error: e.message)
    end
  end

  def message_params
    contents = message.content_type == 'text' ? message_params_text : message_params_media
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
      {
        type: :file,
        fileMimeType: a.content_type,
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
