class Captain::Tools::Copilot::SearchArticlesService < Captain::Tools::BaseTool
  def self.name
    'search_articles'
  end
  description 'Search articles based on parameters'
  param :query, desc: 'Search articles by title or content (partial match)', required: false
  param :category_id, type: :number, desc: 'Filter articles by category ID', required: false
  param :status, type: :string, desc: 'Filter articles by status - MUST BE ONE OF: draft, published, archived', required: false

  def execute(query: nil, category_id: nil, status: nil)
    articles = fetch_articles(query: query, category_id: category_id, status: status)
    return 'No articles found' unless articles.exists?

    total_count = articles.count
    articles = articles.limit(100)
    <<~RESPONSE
      #{total_count > 100 ? "Found #{total_count} articles (showing first 100)" : "Total number of articles: #{total_count}"}
      #{articles.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def fetch_articles(query:, category_id:, status:)
    articles = Article.where(account_id: @assistant.account_id)
    articles = articles.where('title ILIKE :query OR content ILIKE :query', query: "%#{query}%") if query.present?
    articles = articles.where(category_id: category_id) if category_id.present?
    articles = articles.where(status: status) if status.present?
    articles
  end
end
