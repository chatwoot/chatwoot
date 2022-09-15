json.payload do
  json.array! @articles, partial: 'public/api/v1/models/article.json.jbuilder', as: :article
end

json.meta do
  json.articles_count @articles.published.size
end
