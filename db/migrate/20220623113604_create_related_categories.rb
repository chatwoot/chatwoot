class CreateRelatedCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :related_categories do |t|
      t.bigint :category_id
      t.bigint :related_category_id
      t.timestamps
    end

    add_index :related_categories, [:category_id, :related_category_id], unique: true
    add_index :related_categories, [:related_category_id, :category_id], unique: true
  end
end
