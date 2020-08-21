class AddCustomAttributesToContacts < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :custom_attributes, :jsonb, default: {}
  end
end
