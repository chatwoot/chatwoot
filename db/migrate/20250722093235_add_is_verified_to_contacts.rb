class AddIsVerifiedToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :verified, :boolean, default: false, null: false

    add_index :contacts, [:account_id, :verified], name: 'index_contacts_on_account_id_and_verified'
  end
end
