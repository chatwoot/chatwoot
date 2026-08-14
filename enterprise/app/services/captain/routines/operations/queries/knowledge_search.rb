class Captain::Routines::Operations::Queries::KnowledgeSearch < Captain::Routines::Operations::Query
  returns :collection, of: :knowledge_result

  configure(
    name: 'knowledge.search', effect: 'read',
    description: 'Search accessible FAQs, help-center articles, and Captain documents.',
    arguments: {
      query: 'semantic search query', language: 'optional language code', limit: 'maximum number of results'
    },
    required: %w[query]
  )

  def execute(query:, language: nil, limit: 5)
    result_limit = limit.to_i.clamp(1, 20)
    article_results = search_articles(query, language, result_limit)
    return article_results if article_results.length == result_limit

    article_results + search_faqs(query, result_limit - article_results.length)
  end

  private

  def search_articles(query, language, limit)
    articles = account.articles.published
    articles = articles.where(locale: language) if language.present?
    articles.text_search(query).limit(limit).map do |article|
      {
        'type' => 'help_center_article',
        'id' => article.id,
        'title' => article.title,
        'content' => article.content,
        'locale' => article.locale,
        'url' => Rails.application.routes.url_helpers.public_portal_article_path(
          slug: article.portal.slug,
          article_slug: article.slug
        )
      }
    end
  end

  def search_faqs(query, limit)
    escaped_query = ActiveRecord::Base.sanitize_sql_like(query.to_s)
    account.captain_assistant_responses.approved
           .where('question ILIKE :query OR answer ILIKE :query', query: "%#{escaped_query}%")
           .limit(limit)
           .map do |response|
      {
        'type' => 'captain_faq',
        'id' => response.id,
        'question' => response.question,
        'answer' => response.answer,
        'url' => response.customer_visible_source_url
      }
    end
  end
end
