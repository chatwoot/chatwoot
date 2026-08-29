class AddProviderConfigToChannelTwilioSms < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_twilio_sms, :provider_config, :jsonb, default: {}
  end
end
