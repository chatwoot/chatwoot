class AddBusinessConfigToChannelTelegram < ActiveRecord::Migration[7.1]
  def up
    add_column :channel_telegram, :business_config, :jsonb, default: {}, null: false
    add_column :channel_telegram, :business_config_checked_at, :datetime
    add_column :channel_telegram, :business_config_error, :string, limit: 500

    Migration::SyncTelegramBusinessConfigJob.perform_later
  end

  def down
    remove_column :channel_telegram, :business_config_error
    remove_column :channel_telegram, :business_config_checked_at
    remove_column :channel_telegram, :business_config
  end
end
