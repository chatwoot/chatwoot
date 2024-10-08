class Zalo::SendOnZaloService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloOa
  end

  def perform_reply
    response = send_message
    return unless response['error'] == -216

    ## access token is expired
    resp_refresh = channel.refresh_access_token(channel)
    if resp_refresh['error_description']
      message.update!(status: :failed, external_error: resp_refresh['error_description'])
    else
      send_message
    end
  end

  def send_message
    response = channel.send_message(message.conversation.contact_inbox.source_id, message, channel.oa_access_token).last
    if (response['error']).zero? && response['data']['message_id']
      message.update!(source_id: response['data']['message_id'])
    elsif response['error'] != -216
      message.update!(status: :failed, external_error: response['message'])
    end
    response
  end
end
