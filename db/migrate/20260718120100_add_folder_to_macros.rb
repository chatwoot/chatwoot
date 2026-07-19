class AddFolderToMacros < ActiveRecord::Migration[7.1]
  def change
    add_column :macros, :folder, :string, default: '', null: false, if_not_exists: true
    add_index :macros, [:account_id, :folder], if_not_exists: true
  end
end
