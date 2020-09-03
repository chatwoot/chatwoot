class RenameMessagePrivate < ActiveRecord::Migration[6.0]
  def change
    rename_column :messages, :private, :is_private_note
  end
end
