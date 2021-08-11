class AddIndexToContacts < ActiveRecord::Migration[6.0]
  def change
    add_index :contacts, [:phone_number, :account_id]
  end
end
