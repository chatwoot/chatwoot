class SdkPush::FcmService
  pattr_initialize [:delivery!]

  def perform
    configuration = delivery.sdk_push_device.sdk_app.android_configuration
    client = Notification::FcmService.new(configuration.project_id, configuration.service_account).fcm_client
    response = client.send_v1(notification(configuration))
    record_response(response)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise CustomExceptions::SdkPushError, "FCM transport error: #{e.class.name}"
  end

  private

  def record_response(response)
    status = response[:status_code].to_i
    body = JSON.parse(response[:body])
    reason = body.dig('error', 'status')
    raise CustomExceptions::SdkPushError, "FCM temporarily unavailable: #{reason}" if status == 429 || status >= 500

    delivery.update!(status: status.between?(200, 299) ? 'accepted' : 'rejected', reason: reason)
    details = body.dig('error', 'details') || []
    return unless details.any? { |detail| detail['errorCode'] == 'UNREGISTERED' }

    delivery.sdk_push_device.update!(invalidated_at: Time.current)
  end

  def notification(configuration)
    device = delivery.sdk_push_device
    {
      token: device.device_token,
      notification: { title: device.sdk_app.name, body: I18n.t(delivery.message_id ? 'sdk_push.reply' : 'sdk_push.test') },
      data: { chatwoot_sdk_app_id: device.sdk_app.app_id, chatwoot_inbox_id: device.sdk_app.inbox_id.to_s,
              chatwoot_conversation_id: delivery.message&.conversation&.display_id.to_s },
      android: { priority: 'high', restricted_package_name: configuration.package_name,
                 notification: { channel_id: 'chatwoot_support', tag: "chatwoot_#{delivery.message&.conversation&.display_id}" } }
    }
  end
end
