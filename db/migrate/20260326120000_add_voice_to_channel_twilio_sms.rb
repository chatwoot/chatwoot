class AddVoiceToChannelTwilioSms < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_twilio_sms, :voice_enabled, :boolean, default: false, null: false
    add_column :channel_twilio_sms, :twiml_app_sid, :string
    add_column :channel_twilio_sms, :api_key_secret, :string
  end
end
