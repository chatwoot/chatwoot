class AddIndexToArticlesCategoryId < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :articles, :category_id, algorithm: :concurrently
  end
end
