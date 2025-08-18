class AddApiKeySidToTwilioSms < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_twilio_sms, :api_key_sid, :string
  end
end
