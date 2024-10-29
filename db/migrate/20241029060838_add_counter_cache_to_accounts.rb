class AddCounterCacheToAccounts < ActiveRecord::Migration[7.0]
  def up
    add_column :accounts, :contactable_contacts_count, :integer, default: 0

    # Initialize the counter for existing records in batches
    Account.in_batches(of: 100) do |batch|
      batch.ids.each do |account_id|
        UpdateContactableContactsCountJob.perform_later(account_id)
      end
    end
  end

  def down
    remove_column :accounts, :contactable_contacts_count
  end
end
