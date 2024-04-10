class AddUniqueValidationIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :channel_twitter_profiles, [:account_id, :profile_id], unique: true
    add_index :channel_twilio_sms, [:account_id, :phone_number], unique: true
    add_index :webhooks, [:account_id, :url], unique: true
  end
end
