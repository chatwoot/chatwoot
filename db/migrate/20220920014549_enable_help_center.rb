class EnableHelpCenter < ActiveRecord::Migration[6.1]
  def change
    return if ENV['DEPLOYMENT_ENV'] == 'cloud'

    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features('help_center')
        account.save!
      end
    end
  end
end
