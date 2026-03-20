class Twilio::SendOnTwilioService < Base::SendOnChannelService
  def send_csat_template_message(phone_number:, content_sid:, content_variables: {})
    send_params = {
      to: phone_number,
      content_sid: content_sid
    }

    send_params[:content_variables] = content_variables.to_json if content_variables.present?
    send_params[:status_callback] = channel.send(:twilio_delivery_status_index_url) if channel.respond_to?(:twilio_delivery_status_index_url, true)

    # Add messaging service or from number
    send_params = send_params.merge(channel.send(:send_message_from))

    twilio_message = channel.send(:client).messages.create(**send_params) # rubocop:disable Rails/SaveBang

    { success: true, message_id: twilio_message.sid }
  rescue Twilio::REST::TwilioError, Twilio::REST::RestError => e
    Rails.logger.error "Failed to send Twilio template message: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def channel_class
    Channel::TwilioSms
  end

  def perform_reply
    begin
      twilio_message = if template_params.present?
                         send_template_message
                       else
                         channel.send_message(**message_params)
                       end
    rescue Twilio::REST::TwilioError, Twilio::REST::RestError => e
      Messages::StatusUpdateService.new(message, 'failed', e.message).perform
    end
    message.update!(source_id: twilio_message.sid) if twilio_message
  end

  def send_template_message
    content_sid, content_variables = process_template_params

    if content_sid.blank?
      message.update!(status: :failed, external_error: 'Template not found')
      return nil
    end

    send_params = {
      to: contact_inbox.source_id,
      content_sid: content_sid
    }

    send_params[:content_variables] = content_variables.to_json if content_variables.present?
    send_params[:status_callback] = channel.send(:twilio_delivery_status_index_url) if channel.respond_to?(:twilio_delivery_status_index_url, true)

    # Add messaging service or from number
    send_params = send_params.merge(channel.send(:send_message_from))

    channel.send(:client).messages.create(**send_params) # rubocop:disable Rails/SaveBang
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end

  def process_template_params
    return [nil, nil] if template_params.blank?

    Twilio::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params,
      message: message
    ).call
  end

  def message_params
    {
      body: message.outgoing_content,
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
