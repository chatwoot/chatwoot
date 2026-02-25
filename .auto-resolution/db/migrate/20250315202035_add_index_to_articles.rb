class AddIndexToArticles < ActiveRecord::Migration[7.0]
  def change
    add_index :articles, :status unless index_exists?(:articles, :status)
    add_index :articles, :views unless index_exists?(:articles, :views)
    add_index :articles, :portal_id unless index_exists?(:articles, :portal_id)
    add_index :articles, :account_id unless index_exists?(:articles, :account_id)
  end
end
