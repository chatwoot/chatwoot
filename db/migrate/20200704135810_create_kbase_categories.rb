class CreateKbaseCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_categories do |t|
      t.integer :account_id, null: false
      t.integer :portal_id, null: false
      t.string :name
      t.text :description
      t.integer :position

      t.timestamps
    end
  end
end
