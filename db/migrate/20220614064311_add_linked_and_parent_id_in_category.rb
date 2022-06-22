class AddLinkedAndParentIdInCategory < ActiveRecord::Migration[6.1]
  def change
    add_reference :categories, :parent_category, foreign_key: { to_table: :categories }

    create_table :linked_categories, id: false do |t|
      t.bigint :category_id
      t.bigint :linked_category_id
      t.timestamps
    end

    add_index :linked_categories, [:category_id, :linked_category_id], unique: true
    add_index :linked_categories, [:linked_category_id, :category_id], unique: true
  end
end
