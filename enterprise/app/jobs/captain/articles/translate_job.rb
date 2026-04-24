class Captain::Articles::TranslateJob < ApplicationJob
  queue_as :low

  def perform(account, article_id, target_locale, target_category_id, user)
    @account = account
    @source_article = account.articles.find(article_id)

    service = Captain::Llm::ArticleTranslationService.new(account: account)
    target_language = language_name_for(target_locale)

    translated_title = service.translate_title(@source_article.title, target_language: target_language)
    translated_content = if @source_article.content.present?
                           service.translate_content(@source_article.content, target_language: target_language)
                         else
                           @source_article.content
                         end

    existing = find_existing_translation(target_locale)

    if existing
      existing.update!(title: translated_title, content: translated_content, description: @source_article.description)
    else
      create_translated_article(translated_title, translated_content, target_locale, target_category_id, user)
    end
  end

  private

  def find_existing_translation(target_locale)
    root_id = Article.find_root_article_id(@source_article)
    @source_article.portal.articles.find_by(associated_article_id: root_id, locale: target_locale)
  end

  def create_translated_article(translated_title, translated_content, target_locale, target_category_id, user)
    @source_article.portal.articles.create!(
      title: translated_title,
      content: translated_content,
      description: @source_article.description,
      category_id: target_category_id,
      locale: target_locale,
      author_id: user.id,
      status: :draft,
      associated_article_id: Article.find_root_article_id(@source_article)
    )
  end

  def language_name_for(locale_code)
    language_map = YAML.load_file(Rails.root.join('config/languages/language_map.yml'))
    language_map[locale_code] || locale_code
  end
end
