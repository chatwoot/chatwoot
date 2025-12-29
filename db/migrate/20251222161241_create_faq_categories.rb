class CreateFaqCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :faq_categories do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :parent, foreign_key: { to_table: :faq_categories }, null: true
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0, null: false
      t.boolean :is_visible, default: true, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :updated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :faq_categories, %i[account_id parent_id]
    add_index :faq_categories, %i[account_id position]
    add_index :faq_categories, :is_visible
  end
end
