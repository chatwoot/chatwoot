class Twilio::VoiceTeardownService
  pattr_initialize [:channel!]

  def perform
    delete_twiml_app if channel.twiml_app_sid.present?
    clear_number_webhooks
  ensure
    clear_voice_credentials
  end

  private

  def delete_twiml_app
    channel.client.applications(channel.twiml_app_sid).delete
  rescue StandardError => e
    Rails.logger.error("TWILIO_VOICE_TEARDOWN_ERROR: #{e.class} #{e.message} phone=#{channel.phone_number} account=#{channel.account_id}")
  end

  def clear_number_webhooks
    numbers = channel.client.incoming_phone_numbers.list(phone_number: channel.phone_number)
    return if numbers.empty?

    channel.client
           .incoming_phone_numbers(numbers.first.sid)
           .update(voice_url: '', status_callback: '')
  rescue StandardError => e
    Rails.logger.error("TWILIO_VOICE_TEARDOWN_WEBHOOK_ERROR: #{e.class} #{e.message} phone=#{channel.phone_number} account=#{channel.account_id}")
  end

  def clear_voice_credentials
    channel.update(twiml_app_sid: nil)
  end
end
