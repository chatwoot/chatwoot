class AddAssociatedArticleId < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :associated_article_id, :integer, null: true
    add_reference :articles, :associated_article_id, foreign_key: { to_table: :articles }
  end
end
