class AddIndexOnContactTypeAndAccountIdToContacts < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :contacts, [:account_id, :contact_type], name: 'index_contacts_on_account_id_and_contact_type', algorithm: :concurrently
  end
end
