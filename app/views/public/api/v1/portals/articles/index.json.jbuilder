json.payload do
  json.array! @articles, partial: 'public/api/v1/models/article.json.jbuilder', as: :article
end
