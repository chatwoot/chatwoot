class CreateFaqItems < ActiveRecord::Migration[7.1]
  def change
    create_table :faq_items do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :faq_category, foreign_key: true, null: true
      t.integer :position, default: 0, null: false
      t.boolean :is_visible, default: true, null: false
      t.jsonb :translations, default: {}, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :updated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :faq_items, %i[account_id faq_category_id]
    add_index :faq_items, %i[account_id position]
    add_index :faq_items, :is_visible
    add_index :faq_items, :translations, using: :gin
  end
end
