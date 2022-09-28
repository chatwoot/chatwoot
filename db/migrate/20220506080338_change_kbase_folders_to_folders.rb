class ChangeKbaseFoldersToFolders < ActiveRecord::Migration[6.1]
  def change
    rename_table :kbase_folders, :folders
  end
end
