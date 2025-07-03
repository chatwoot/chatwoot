class Captain::Tools::SearchArticlesTool < Captain::Tools::BaseAgentTool
  description 'Search articles based on parameters'
  param :query, type: 'string', desc: 'Search articles by title or content (partial match)'
  param :category_id, type: 'number', desc: 'Filter articles by category ID', required: false
  param :status, type: 'string', desc: 'Filter articles by status (draft, published, archived)', required: false

  def perform(_tool_context, query:, category_id: nil, status: nil)
    log_tool_usage('search_articles', { query: query, category_id: category_id, status: status })

    return 'Missing required parameters' if query.blank?

    articles = fetch_articles(query, category_id, status)

    return 'No articles found' unless articles.exists?

    total_count = articles.count
    articles = articles.limit(100)

    <<~RESPONSE
      #{total_count > 100 ? "Found #{total_count} articles (showing first 100)" : "Total number of articles: #{total_count}"}
      #{articles.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  protected

  def required_permission
    'knowledge_base_manage'
  end

  private

  def fetch_articles(query, category_id, status)
    articles = account_scoped(Article)
    articles = articles.where('title ILIKE :query OR content ILIKE :query', query: "%#{query}%") if query.present?
    articles = articles.where(category_id: category_id) if category_id.present?
    articles = articles.where(status: status) if status.present?
    articles
  end
end