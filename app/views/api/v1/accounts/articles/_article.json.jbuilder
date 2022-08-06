json.id article.id
json.category_id article.category_id
json.title article.title
json.content article.content
json.description article.description
json.status article.status
json.account_id article.account_id
json.updated_at article.updated_at.to_i

if article.portal.present?
  json.portal do
    json.partial! 'api/v1/accounts/portals/portal.json.jbuilder', portal: article.portal
  end
end

json.views article.views

if article.author.present?
  json.author do
    json.partial! 'api/v1/models/agent.json.jbuilder', resource: article.author
  end
end

json.associated_articles do
  if article.associated_articles.any?
    json.array! article.associated_articles.each do |associated_article|
      json.partial! 'api/v1/accounts/articles/associated_article.json.jbuilder', article: associated_article
    end
  end
end
