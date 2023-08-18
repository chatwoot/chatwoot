class AddIsDeletedToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :is_deleted, :boolean, default: false
  end
end
