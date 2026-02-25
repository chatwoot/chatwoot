class AddCustomRoles < ActiveRecord::Migration[7.0]
  def change
    # Create the roles table
    create_table :custom_roles do |t|
      t.string :name
      t.string :description
      t.references :account, null: false
      t.text :permissions, array: true, default: []
      t.timestamps
    end

    # Associate the custom role with account user
    # Add the custom_role_id column to the account_users table
    add_reference :account_users, :custom_role, optional: true
  end
end
