json.id article.id
json.category_id article.category_id
json.title article.title
json.content article.content
json.description article.description
json.status article.status
json.account_id article.account_id
json.last_updated_at article.updated_at
json.views article.views

if article.author.present?
  json.author do
    json.partial! 'api/v1/models/agent.json.jbuilder', resource: article.author
  end
end
