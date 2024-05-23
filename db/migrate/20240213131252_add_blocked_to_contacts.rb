class AddBlockedToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :blocked, :boolean, default: false, null: false
    add_index :contacts, :blocked
  end
end
