class Captain::Tools::Copilot::GetArticleService < Captain::Tools::BaseTool
  def self.name
    'get_article'
  end
  description 'Get details of an article including its content and metadata'
  param :article_id, type: :number, desc: 'The ID of the article to retrieve', required: true

  def execute(article_id:)
    article = Article.find_by(id: article_id, account_id: @assistant.account_id)
    return 'Article not found' if article.nil?

    article.to_llm_text
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end
end
