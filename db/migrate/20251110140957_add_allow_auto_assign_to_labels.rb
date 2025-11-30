class AddAllowAutoAssignToLabels < ActiveRecord::Migration[7.1]
  def change
    add_column :labels, :allow_auto_assign, :boolean, default: false
    add_index :labels, :allow_auto_assign
  end
end
