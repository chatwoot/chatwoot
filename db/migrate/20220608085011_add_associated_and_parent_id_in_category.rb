class AddAssociatedAndParentIdInCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :associated_category_id, :integer, null: true
    add_column :categories, :parent_category_id, :integer, null: true
    add_reference :categories, :associated_category_id, foreign_key: { to_table: :categories }
    add_reference :categories, :parent_category_id, foreign_key: { to_table: :categories }
  end
end
