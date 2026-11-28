class AddVerifiedAttributesToContacts < ActiveRecord::Migration[8.0]
  def change
    add_column :contacts, :verified_attributes, :jsonb, default: {}, null: false, if_not_exists: true
  end
end
