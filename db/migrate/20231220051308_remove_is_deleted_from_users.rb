class RemoveIsDeletedFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :is_deleted, :boolean
  end
end
