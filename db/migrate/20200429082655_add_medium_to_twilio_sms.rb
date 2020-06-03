class AddMediumToTwilioSms < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_twilio_sms, :medium, :integer, index: true, default: 0
  end
end
