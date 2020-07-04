class CreateKbaseArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_articles do |t|
      t.integer :account_id
      t.integer :category_id
      t.integer :folder_id
      t.integer :author_id
      t.string :title
      t.text :content
      t.integer :status
      t.integer :views
      t.string :seo_title
      t.string :seo_description

      t.timestamps
    end
  end
end
