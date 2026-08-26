class AddUniqueTranslationLocaleIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :articles, %i[associated_article_id locale],
              unique: true,
              where: 'associated_article_id IS NOT NULL AND status = 1',
              name: 'index_articles_on_translation_and_locale',
              algorithm: :concurrently
    add_index :categories, %i[associated_category_id locale],
              unique: true,
              where: 'associated_category_id IS NOT NULL',
              name: 'index_categories_on_translation_and_locale',
              algorithm: :concurrently
  end
end
