class AddActiveToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :active, :boolean, default: true, null: false
  end
end
