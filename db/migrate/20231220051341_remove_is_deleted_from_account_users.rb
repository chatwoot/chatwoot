class RemoveIsDeletedFromAccountUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :account_users, :is_deleted, :boolean
  end
end
