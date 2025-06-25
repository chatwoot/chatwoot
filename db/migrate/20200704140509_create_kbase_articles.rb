class CreateKbaseArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_articles do |t|
      t.integer :account_id, null: false
      t.integer :portal_id, null: false
      t.integer :category_id
      t.integer :folder_id
      t.integer :author_id
      t.string :title
      t.text :description
      t.text :content
      t.integer :status
      t.integer :views

      t.timestamps
    end
  end
end
