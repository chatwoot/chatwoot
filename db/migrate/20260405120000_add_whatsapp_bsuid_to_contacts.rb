class AddWhatsappBsuidToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :whatsapp_bsuid, :string
    add_index :contacts, [:account_id, :whatsapp_bsuid],
              unique: true,
              where: 'whatsapp_bsuid IS NOT NULL',
              name: 'index_contacts_on_account_id_and_whatsapp_bsuid'
  end
end
