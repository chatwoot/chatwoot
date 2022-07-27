json.payload do
  json.array! @articles, partial: 'article', as: :article
end

json.meta do
  json.articles_count @articles.size
end
