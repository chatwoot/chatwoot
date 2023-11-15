class AddFeaturesToAccounts < ActiveRecord::Migration[6.1]
  def change
    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features(
          'agent_management',
          'automations',
          'canned_responses',
          'custom_attributes',
          'inbox_management',
          'integrations',
          'labels',
          'team_management',
          'voice_recorder'
        )
        account.save!
      end
    end
  end
end
