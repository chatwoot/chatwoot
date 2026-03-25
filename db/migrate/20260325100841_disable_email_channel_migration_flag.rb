class DisableEmailChannelMigrationFlag < ActiveRecord::Migration[7.1]
  def up
    Account.feature_email_channel_migration.find_each(batch_size: 100) do |account|
      account.disable_features(:email_channel_migration)
      account.save!(validate: false)
    end
  end
end
