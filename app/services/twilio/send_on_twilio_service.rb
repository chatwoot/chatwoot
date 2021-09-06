class Twilio::SendOnTwilioService < Base::SendOnChannelService
  private

  def channel_class
    Channel::TwilioSms
  end

  def perform_reply
    begin
      twilio_message = client.messages.create(**message_params)
    rescue Twilio::REST::TwilioError => e
      Rails.logger.info "Twilio Error: #{e.message}"
    end
    message.update!(source_id: twilio_message.sid)
  end

  def message_params
    params = {
      body: message.content,
      from: channel.phone_number,
      to: contact_inbox.source_id
    }
    params[:media_url] = attachments if message.attachments.present?
    params
  end

  def attachments
    message.attachments.map(&:file_url)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def client
    ::Twilio::REST::Client.new(channel.account_sid, channel.auth_token)
  end
end
