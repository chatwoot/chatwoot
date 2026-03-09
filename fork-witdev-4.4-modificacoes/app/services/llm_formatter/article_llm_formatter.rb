class LlmFormatter::ArticleLlmFormatter
  attr_reader :article

  def initialize(article)
    @article = article
  end

  def format(*)
    <<~TEXT
      Title: #{article.title}
      ID: #{article.id}
      Status: #{article.status}
      Category: #{article.category&.name || 'Uncategorized'}
      Author: #{article.author&.name || 'Unknown'}
      Views: #{article.views}
      Created At: #{article.created_at}
      Updated At: #{article.updated_at}
      Content:
      #{article.content}
    TEXT
  end
end
