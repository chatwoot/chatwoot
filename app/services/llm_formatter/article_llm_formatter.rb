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
      Public URL: #{public_url || 'None, because the article is not published'}
      Category: #{article.category&.name || 'Uncategorized'}
      Author: #{article.author&.name || 'Unknown'}
      Views: #{article.views}
      Created At: #{article.created_at}
      Updated At: #{article.updated_at}
      Content:
      #{article.content}
    TEXT
  end

  private

  # The help center link the portal's sitemap lists, so the model can share an article without making up its URL.
  def public_url
    return unless article.published?

    "#{article.portal.help_center_url}/hc/#{article.portal.slug}/articles/#{article.slug}"
  end
end
