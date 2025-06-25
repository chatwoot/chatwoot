class Twilio::SendOnTwilioService < Base::SendOnChannelService
  private

  def channel_class
    Channel::TwilioSms
  end

  def perform_reply
    begin
      twilio_message = channel.send_message(**message_params)
    rescue Twilio::REST::TwilioError, Twilio::REST::RestError => e
      Messages::StatusUpdateService.new(message, 'failed', e.message).perform
    end
    message.update!(source_id: twilio_message.sid) if twilio_message
  end

  def message_params
    {
      body: message.content,
      to: contact_inbox.source_id,
      media_url: attachments
    }
  end

  def attachments
    message.attachments.map(&:download_url)
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
end
