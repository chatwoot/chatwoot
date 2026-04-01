class Twilio::VoiceTeardownService
  pattr_initialize [:channel!]

  def perform
    delete_twiml_app if channel.twiml_app_sid.present?
  rescue StandardError => e
    Rails.logger.error("TWILIO_VOICE_TEARDOWN_ERROR: #{e.class} #{e.message} phone=#{channel.phone_number} account=#{channel.account_id}")
  ensure
    clear_voice_credentials
  end

  private

  def delete_twiml_app
    twilio_client.applications(channel.twiml_app_sid).delete
  end

  def clear_voice_credentials
    channel.update!(twiml_app_sid: nil)
  end

  def twilio_client
    @twilio_client ||= Twilio::REST::Client.new(channel.account_sid, channel.auth_token)
  end
end
