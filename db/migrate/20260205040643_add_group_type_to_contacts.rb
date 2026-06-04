class AddGroupTypeToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :group_type, :integer, default: 0, null: false
    add_index :contacts, [:account_id, :group_type]
  end
end
