class EnabledNewFeatures < ActiveRecord::Migration[6.1]
  def change
    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features(
          'channel_website',
          'campaigns',
          'reports',
          'crm',
          'auto_resolve_conversations'
        )
        account.save!
      end
    end
  end
end
