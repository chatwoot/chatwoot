class AddContactsPreparationStatusToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :contacts_preparation_status, :integer, default: 0, null: false
    add_column :campaigns, :total_contacts_count, :integer, default: 0
    add_column :campaigns, :prepared_contacts_count, :integer, default: 0

    add_index :campaigns, :contacts_preparation_status
  end
end
