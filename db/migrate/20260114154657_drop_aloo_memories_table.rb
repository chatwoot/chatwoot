class DropAlooMemoriesTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :aloo_memories, if_exists: true
  end

  def down
    # This migration is irreversible - data cannot be recovered
    # If you need to restore the table, use the original migration
    raise ActiveRecord::IrreversibleMigration
  end
end
