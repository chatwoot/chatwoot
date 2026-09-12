class AddParentIdToLabels < ActiveRecord::Migration[7.1]
  def up
    add_reference :labels, :parent, foreign_key: { to_table: :labels }, index: true
    add_column :labels, :depth, :integer
    add_column :labels, :children_count, :integer

    add_index :labels, [:account_id, :parent_id]
  end

  def down
    remove_index :labels, [:account_id, :parent_id]
    remove_column :labels, :children_count
    remove_column :labels, :depth
    remove_reference :labels, :parent, foreign_key: { to_table: :labels }, index: true
  end
end
