class RenameNickNameToDisplayName < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :nickname, :display_name
  end
end
