class RemoveIsAuthorizeFromContacts < ActiveRecord::Migration[7.1]
  def change
    remove_column :contacts, :is_authorize, :boolean
  end
end
