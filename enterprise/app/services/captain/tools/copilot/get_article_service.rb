class Captain::Tools::Copilot::GetArticleService < Captain::Tools::BaseService
  def name
    'get_article'
  end

  def description
    'Get details of an article including its content and metadata'
  end

  def parameters
    {
      type: 'object',
      properties: {
        article_id: {
          type: 'number',
          description: 'The ID of the article to retrieve'
        }
      },
      required: %w[article_id]
    }
  end

  def execute(arguments)
    article_id = arguments['article_id']

    Rails.logger.info { "#{self.class.name}: Article ID: #{article_id}" }

    return 'Missing required parameters' if article_id.blank?

    article = Article.find_by(id: article_id, account_id: @assistant.account_id)
    return 'Article not found' if article.nil?

    article.to_llm_text
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end
end
