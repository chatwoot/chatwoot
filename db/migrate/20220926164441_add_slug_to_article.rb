class AddSlugToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :slug, :string, index: true, default: ''

    Article.all.each do |article|
      slug = article.title.underscore.parameterize(separator: "_")
      article.update!(slug: slug)
    end

    add_index :articles, :slug
  end
end
