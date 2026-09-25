class SdkPush::ApnsService
  pattr_initialize [:delivery!]

  def perform
    connection = build_connection
    response = connection.push(notification, timeout: 5)
    raise CustomExceptions::SdkPushError, 'APNs request timed out' unless response

    record_response(response)
  rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
    raise CustomExceptions::SdkPushError, "APNs transport error: #{e.class.name}"
  ensure
    connection&.close
  end

  private

  def build_connection
    configuration = delivery.sdk_push_device.sdk_app.ios_configuration
    options = { auth_method: :token, cert_path: StringIO.new(configuration.private_key), key_id: configuration.key_id,
                team_id: configuration.team_id, connect_timeout: 5 }
    return Apnotic::Connection.development(options) if delivery.sdk_push_device.environment == 'development'

    Apnotic::Connection.new(options)
  end

  def notification
    device = delivery.sdk_push_device
    Apnotic::Notification.new(device.device_token).tap do |push|
      push.topic = device.sdk_app.ios_configuration.bundle_id
      push.push_type = 'alert'
      push.priority = '10'
      push.apns_id = delivery.apns_id
      push.expiration = 1.hour.from_now.to_i.to_s
      push.alert = alert
      push.sound = 'default'
      push.custom_payload = destination
    end
  end

  def destination
    { chatwoot: { inbox_id: delivery.sdk_push_device.sdk_app.inbox_id, conversation_id: delivery.message&.conversation&.display_id } }
  end

  def alert
    { title: delivery.sdk_push_device.sdk_app.name, body: I18n.t(delivery.message_id ? 'sdk_push.reply' : 'sdk_push.test') }
  end

  def record_response(response)
    reason = response.ok? ? nil : response.body['reason']
    raise CustomExceptions::SdkPushError, "APNs temporarily unavailable: #{reason}" if response.status.to_i == 429 || response.status.to_i >= 500

    delivery.update!(status: response.ok? ? 'accepted' : 'rejected', reason: reason)
    delivery.sdk_push_device.update!(invalidated_at: Time.current) if response.status.to_i == 410 || reason == 'BadDeviceToken'
  end
end
