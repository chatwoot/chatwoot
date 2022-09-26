class AddSlugToArticle < ActiveRecord::Migration[6.1]
  def up
    add_column :articles, :slug, :string, default: ''

    update_past_articles_with_slug

    add_index :articles, :slug
    change_column_null(:articles, :slug, false)
  end

  def down
    remove_column(:articles, :slug)
  end

  def update_past_articles_with_slug
    Article.all.each do |article|
      slug = article.title.underscore.parameterize(separator: '_')
      article.update!(slug: slug)
    end
  end
end
