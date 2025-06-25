class RenameReferenceId < ActiveRecord::Migration[6.0]
  def change
    rename_column :conversations, :reference_id, :identifier
  end
end
