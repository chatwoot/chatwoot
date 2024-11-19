json.id article.id
json.category_id article.category_id
json.title article.title
json.content article.content
json.description article.description
json.status article.status
json.account_id article.account_id

if article.portal.present?
  json.portal do
    json.partial! 'api/v1/accounts/portals/portal', formats: [:json], portal: article.portal, articles: []
  end
end

json.views article.views

if article.author.present?
  json.author do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: article.author
  end
end
