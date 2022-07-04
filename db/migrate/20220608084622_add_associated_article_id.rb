class AddAssociatedArticleId < ActiveRecord::Migration[6.1]
  def change
    add_reference :articles, :linked_article, foreign_key: { to_table: :articles }
  end
end
