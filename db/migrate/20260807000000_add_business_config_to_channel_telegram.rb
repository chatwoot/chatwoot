class AddBusinessConfigToChannelTelegram < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_telegram, :business_config, :jsonb, default: {}, null: false
    add_column :channel_telegram, :business_config_checked_at, :datetime
    add_column :channel_telegram, :business_config_error, :string, limit: 500
  end
end
