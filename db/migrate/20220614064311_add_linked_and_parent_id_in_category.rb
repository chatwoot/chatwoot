class AddLinkedAndParentIdInCategory < ActiveRecord::Migration[6.1]
  def change
    # add_reference :categories, :linked_category, foreign_key: { to_table: :categories }
    add_reference :categories, :parent_category, foreign_key: { to_table: :categories }
    create_table :linked_categories do |t|
      t.column :category_id1
      t.foreign_key :categories
      t.column :category_id2
      t.foreign_key :categories
    end
  end
end
