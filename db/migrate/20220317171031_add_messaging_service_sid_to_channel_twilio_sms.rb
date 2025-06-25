class AddMessagingServiceSidToChannelTwilioSms < ActiveRecord::Migration[6.1]
  def change
    change_column_null :channel_twilio_sms, :phone_number, true
    add_column :channel_twilio_sms, :messaging_service_sid, :string
    add_index :channel_twilio_sms, [:messaging_service_sid], unique: true
  end
end
