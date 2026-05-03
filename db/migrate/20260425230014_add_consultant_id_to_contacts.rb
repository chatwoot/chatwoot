class AddConsultantIdToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :consultant_id, :bigint
    add_index :contacts, :consultant_id
    add_foreign_key :contacts, :users, column: :consultant_id, on_delete: :nullify
  end
end
