class RenameFbIdToSourceId < ActiveRecord::Migration[6.0]
  def change
    rename_column :messages, :fb_id, :source_id

    add_index(:messages, :source_id)
  end
end
