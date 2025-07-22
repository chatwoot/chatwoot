class AddIsVerifiedToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :is_verified, :boolean, default: false, null: false
    add_index :contacts, :is_verified
    add_index :contacts, [:account_id, :is_verified], name: 'index_contacts_on_account_id_and_is_verified'
  end
end
