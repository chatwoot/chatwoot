class AddUnoIdentityFieldsToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :bsuid, :string
    add_column :contacts, :whatsapp_username, :string

    add_index :contacts, [:account_id, :bsuid], unique: true, where: 'bsuid IS NOT NULL', name: 'index_contacts_on_account_id_and_bsuid'
    add_index :contacts, [:account_id, :whatsapp_username], where: 'whatsapp_username IS NOT NULL', name: 'index_contacts_on_account_id_and_whatsapp_username'
  end
end
