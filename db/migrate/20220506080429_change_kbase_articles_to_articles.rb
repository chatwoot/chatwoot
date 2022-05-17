class ChangeKbaseArticlesToArticles < ActiveRecord::Migration[6.1]
  def change
    rename_table :kbase_articles, :articles
  end
end
