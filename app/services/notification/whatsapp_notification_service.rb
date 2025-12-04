# frozen_string_literal: true

class Notification::WhatsappNotificationService
  pattr_initialize [:notification!]

  def perform
    return unless user_subscribed_to_notification?
    return unless user_has_whatsapp_contact?

    send_whatsapp_notification
  end

  private

  delegate :user, to: :notification
  delegate :notification_settings, to: :user

  def user_subscribed_to_notification?
    notification_setting = notification_settings.find_by(account_id: notification.account.id)
    return false if notification_setting.blank?

    # Verifica flag: whatsapp_#{notification_type}?
    notification_setting.public_send("whatsapp_#{notification.notification_type}?")
  end

  def user_has_whatsapp_contact?
    user.phone_number.present?
  end

  def send_whatsapp_notification
    phone_number = format_phone_number(user.phone_number)
    message_text = build_notification_message

    response = HTTParty.post(
      "#{whapi_gate_url}/messages/text",
      headers: whapi_headers,
      body: {
        to: phone_number,
        body: message_text
      }.to_json
    )

    log_notification_result(response)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP NOTIFICATION] Error sending to #{user.phone_number}: #{e.message}"
  end

  def build_notification_message
    # Construir mensaje con formato WhatsApp (negrita con *)
    <<~MESSAGE
      *#{notification.push_message_title}*

      #{notification.push_message_body}

      Ver conversación: #{build_action_url}
    MESSAGE
  end

  def build_action_url
    frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    "#{frontend_url}/app/accounts/#{notification.account_id}/conversations/#{notification.conversation.display_id}"
  end

  def format_phone_number(phone)
    # Remover + y cualquier otro carácter no numérico
    phone.gsub(/[^0-9]/, '')
  end

  def whapi_gate_url
    ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')
  end

  def whapi_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('WHAPI_ADMIN_CHANNEL_TOKEN')}"
    }
  end

  def log_notification_result(response)
    if response.success?
      Rails.logger.info "[WHATSAPP NOTIFICATION] Sent to #{user.phone_number} - Notification ##{notification.id} - response: #{response.body}"
    else
      Rails.logger.error "[WHATSAPP NOTIFICATION] Failed to send to #{user.phone_number} - #{response.code}: #{response.body}"
    end
  end
end
