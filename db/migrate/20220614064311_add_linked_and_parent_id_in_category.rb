class AddLinkedAndParentIdInCategory < ActiveRecord::Migration[6.1]
  def change
    # add_reference :categories, :linked_category, foreign_key: { to_table: :categories }
    add_reference :categories, :parent_category, foreign_key: { to_table: :categories }
    create_table :linked_categories do |t|
      t.bigint :category_id1
      t.bigint :category_id2
      t.timestamps
    end

    add_index :linked_categories, [:category_id1, :category_id2], unique: true
  end
end
