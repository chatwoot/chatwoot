class AddMiddleNameAndLastNameToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :middle_name, :string, default: ''
    add_column :contacts, :last_name, :string, default: ''
  end
end
