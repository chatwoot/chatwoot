class Captain::Tools::Copilot::SearchArticleService < Captain::Tools::BaseService
  def name
    'search_article'
  end

  def description
    'Search for articles based on query parameters'
  end

  def parameters
    {
      type: 'object',
      properties: {
        account_id: {
          type: 'number',
          description: 'The ID of the account to search articles in'
        },
        query: {
          type: 'string',
          description: 'Search articles by title or content (partial match)'
        },
        category_id: {
          type: 'number',
          description: 'Filter articles by category ID'
        },
        status: {
          type: 'string',
          enum: %w[draft published archived],
          description: 'Filter articles by status'
        }
      },
      required: %w[account_id]
    }
  end

  def execute(arguments)
    account_id = arguments['account_id']
    query = arguments['query']
    category_id = arguments['category_id']
    status = arguments['status']

    Rails.logger.info do
      "[CAPTAIN][SearchArticle] account_id: #{account_id}, query: #{query}, category_id: #{category_id}, status: #{status}"
    end

    return 'Missing required parameters' if account_id.blank?

    articles = Article.where(account_id: account_id)
    articles = articles.where('title ILIKE :query OR content ILIKE :query', query: "%#{query}%") if query.present?
    articles = articles.where(category_id: category_id) if category_id.present?
    articles = articles.where(status: status) if status.present?

    return 'No articles found' unless articles.exists?

    total_count = articles.count
    articles = articles.limit(100)

    <<~RESPONSE
      #{total_count > 100 ? "Found #{total_count} articles (showing first 100)" : "Total number of articles: #{total_count}"}
      #{articles.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end
end
