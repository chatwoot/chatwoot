class EnableFeaturesInAccounts < ActiveRecord::Migration[7.0]
  def change
    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features('insert_article_in_reply', 'ai_assist', 'label_suggestions')
        account.save!
      end
    end
  end
end
