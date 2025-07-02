class Captain::Tools::GetArticleTool < BaseAgentTool
  description 'Get details of an article including its content and metadata'
  param :article_id, type: 'number', desc: 'The ID of the article to retrieve'

  def perform(_tool_context, article_id:)
    log_tool_usage('get_article', { article_id: article_id })

    return 'Missing required parameters' if article_id.blank?

    article = account_scoped(Article).find_by(id: article_id)
    return 'Article not found' if article.nil?

    article.to_llm_text
  end

  protected

  def required_permission
    'knowledge_base_manage'
  end
end