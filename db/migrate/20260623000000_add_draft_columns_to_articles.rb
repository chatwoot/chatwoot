class AddDraftColumnsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :draft_title, :string
    add_column :articles, :draft_content, :text
  end
end
