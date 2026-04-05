class AddWhatsappUsernameToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :whatsapp_username, :string
  end
end
