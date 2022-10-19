class AddUniqueIndexToSlug < ActiveRecord::Migration[6.1]
  def change
    remove_index :articles, :slug
    add_index :articles, :slug, unique: true
  end
end
