class AddAccountSidUniqueIndexToChannelTwilioSms < ActiveRecord::Migration[6.1]
  def change
    add_index :channel_twilio_sms, [:account_sid, :phone_number], unique: true
  end
end
