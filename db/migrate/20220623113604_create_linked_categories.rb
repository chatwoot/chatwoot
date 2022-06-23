class CreateLinkedCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :linked_categories do |t|
      t.bigint :category_id
      t.bigint :linked_category_id
      t.timestamps
    end

    add_index :linked_categories, [:category_id, :linked_category_id], unique: true
    add_index :linked_categories, [:linked_category_id, :category_id], unique: true
  end
end
