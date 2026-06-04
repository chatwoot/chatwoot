class Whatsapp::UnoapiWebhookSetupService
  def perform(whatsapp_channel)
    if whatsapp_channel.provider_config['disconnect']
      whatsapp_channel.provider_config.delete('connect')
      whatsapp_channel.provider_config.delete('disconnect')
      return disconnect(whatsapp_channel)
    end
    return true unless whatsapp_channel.provider_config['connect']

    whatsapp_channel.provider_config.delete('connect')
    whatsapp_channel.provider_config.delete('disconnect')
    connect(whatsapp_channel)
  end

  private

  def disconnect(whatsapp_channel)
    phone_number = whatsapp_channel.provider_config['business_account_id']
    Rails.logger.debug { "Disconnecting #{phone_number} from unoapi" }
    response = HTTParty.post("#{url(whatsapp_channel)}/deregister", headers: headers(whatsapp_channel))
    if response.success?
      true
    else
      whatsapp_channel.errors.add(:provider_config, response.body)
      false
    end
  end

  def connect(whatsapp_channel)
    phone_number = whatsapp_channel.provider_config['business_account_id']
    url = url(whatsapp_channel)
    Rails.logger.debug { "Connecting #{phone_number} from unoapi with url #{url}" }
    body = params(whatsapp_channel.provider_config, phone_number)
    response = HTTParty.post("#{url}/register", headers: headers(whatsapp_channel), body: body.to_json)
    Rails.logger.debug { "Response #{response}" }
    return send_message(whatsapp_channel) if response.success?

    whatsapp_channel.errors.add(:provider_config, response.body)
    true
  end

  def send_message(whatsapp_channel)
    phone_number = whatsapp_channel.provider_config['business_account_id']
    Rails.logger.debug { "Save #{phone_number} configuration unoapi" }
    body = {
      messaging_product: :whatsapp,
      to: phone_number,
      type: :text,
      text: {
        body: 'connect...'
      }
    }
    Rails.logger.debug { "Sending message to #{phone_number} unoapi" }
    response = HTTParty.post("#{url(whatsapp_channel)}/messages", headers: headers(whatsapp_channel), body: body.to_json)
    Rails.logger.debug { "Response #{response}" }
    return true if response.success?

    whatsapp_channel.errors.add(:provider_config, response.body)
    false
  end

  def url(whatsapp_channel)
    "#{whatsapp_channel.provider_config['url']}/v15.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def headers(whatsapp_channel)
    {
      Authorization: ENV.fetch('UNOAPI_AUTH_TOKEN', whatsapp_channel.provider_config['api_key']),
      'Content-Type': 'application/json'
    }
  end

  # rubocop:disable Metrics/MethodLength
  def params(provider_config, phone_number)
    {
      ignoreGroupMessages: provider_config['ignore_group_messages'],
      ignoreBroadcastStatuses: provider_config['ignore_broadcast_statuses'],
      ignoreBroadcastMessages: provider_config['ignore_broadcast_messages'],
      ignoreHistoryMessages: provider_config['ignore_history_messages'],
      ignoreOwnMessages: provider_config['ignore_own_messages'],
      ignoreYourselfMessages: provider_config['ignore_yourself_messages'],
      sendConnectionStatus: provider_config['send_connection_status'],
      notifyFailedMessages: provider_config['notify_failed_messages'],
      composingMessage: provider_config['composing_message'],
      rejectCalls: provider_config['reject_calls'],
      messageCallsWebhook: provider_config['message_calls_webhook'],
      webhooks: [
        sendNewMessages: provider_config['webhook_send_new_messages'],
        id: 'default',
        urlAbsolute: "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{phone_number}",
        token: provider_config['webhook_verify_token'],
        header: :Authorization
      ],
      sendReactionAsReply: provider_config['send_reaction_as_reply'],
      sendProfilePicture: provider_config['send_profile_picture'],
      authToken: provider_config['api_key'],
      wavoipToken: provider_config['wavoip_token']
    }
  end
  # rubocop:enable Metrics/MethodLength
end
