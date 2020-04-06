class CreateChannelTwilioSms < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_twilio_sms do |t|
      t.string :phone_number, null: false
      t.string :auth_token, null: false
      t.string :account_sid, null: false
      t.integer :account_id, null: false
      t.timestamps
    end
  end
end
