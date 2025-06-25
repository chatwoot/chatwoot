class AddLocaleToArticle < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :locale, :string, default: 'en', null: false

    set_locale_from_category
  end

  private

  def set_locale_from_category
    Article.find_in_batches do |article_batch|
      article_batch.each do |article|
        locale = if article.category.present?
                   article.category.locale
                 else
                   article.portal.default_locale
                 end
        # rubocop:disable Rails/SkipsModelValidations
        article.update_columns(locale: locale)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
