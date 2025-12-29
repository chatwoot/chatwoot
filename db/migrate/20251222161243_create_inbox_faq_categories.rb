class CreateInboxFaqCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :inbox_faq_categories do |t|
      t.references :inbox, null: false, foreign_key: true
      t.references :faq_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :inbox_faq_categories, %i[inbox_id faq_category_id], unique: true
  end
end
