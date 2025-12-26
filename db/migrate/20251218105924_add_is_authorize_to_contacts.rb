class AddIsAuthorizeToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :is_authorize, :boolean, default: false, null: false
  end
end
