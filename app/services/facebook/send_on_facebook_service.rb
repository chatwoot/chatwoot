class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    send_message_to_facebook fb_text_message_params if message.content.present?

    if message.attachments.present?
      message.attachments.each do |attachment|
        send_message_to_facebook_with_retry(attachment)
      end
    end
  rescue Facebook::Messenger::FacebookError => e
    # TODO : handle specific errors or else page will get disconnected
    handle_facebook_error(e)
    message.update!(status: :failed, external_error: e.message)
  end

  def send_message_to_facebook_with_retry(attachment)
    send_message_to_facebook(fb_attachment_message_params(attachment))
  rescue Facebook::Messenger::FacebookError
    # Retry with another way to send with file data
    result = send_message_with_attachment(attachment)
    if result['error'].present?
      message.update!(status: :failed, external_error: external_error(result))
    elsif result['message_id'].present?
      message.update!(status: :sent, source_id: result['message_id'])
    end
  end

  def send_message_with_attachment(attachment)
    url_upload = "https://graph.facebook.com/v19.0/#{channel.page_id}/messages?access_token=#{channel.page_access_token}"
    url = URI.parse(url_upload)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.path)
    request.content_type = 'multipart/form-data'
    request.set_form fb_attachment_form_data(attachment), 'multipart/form-data'

    response = http.request(request)
    JSON.parse(response.body)
  end

  def send_message_to_facebook(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    parsed_result = JSON.parse(result)
    if parsed_result['error'].present?
      message.update!(status: :failed, external_error: external_error(parsed_result))
      Rails.logger.info "Facebook::SendOnFacebookService: Error sending message to Facebook : Page - #{channel.page_id} : #{result}"
    end
    message.update!(source_id: parsed_result['message_id']) if parsed_result['message_id'].present?
  end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def external_error(response)
    # https://developers.facebook.com/docs/graph-api/guides/error-handling/
    error_message = response['error']['message']
    error_code = response['error']['code']

    "#{error_code} - #{error_message}"
  end

  def fb_attachment_message_params(attachment)
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      },
      messaging_type: 'MESSAGE_TAG',
      tag: 'ACCOUNT_UPDATE'
    }
  end

  def fb_attachment_form_data(attachment)
    [
      ['recipient', { id: contact.get_source_id(inbox.id) }.to_json],
      ['message', { attachment: { type: attachment_type(attachment), payload: {} } }.to_json],
      ['filedata', attachment.file.download]
    ]
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  def handle_facebook_error(exception)
    # Refer: https://github.com/jgorset/facebook-messenger/blob/64fe1f5cef4c1e3fca295b205037f64dfebdbcab/lib/facebook/messenger/error.rb
    return unless exception.to_s.include?('The session has been invalidated') || exception.to_s.include?('Error validating access token')

    channel.authorization_error!
  end
end
