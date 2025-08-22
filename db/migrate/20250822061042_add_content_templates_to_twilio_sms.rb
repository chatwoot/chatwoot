class AddContentTemplatesToTwilioSms < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_twilio_sms, :content_templates, :jsonb, default: {}
    add_column :channel_twilio_sms, :content_templates_last_updated, :datetime
  end
end
