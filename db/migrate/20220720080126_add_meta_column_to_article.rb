class AddMetaColumnToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :meta, :jsonb, default: {}
  end
end
