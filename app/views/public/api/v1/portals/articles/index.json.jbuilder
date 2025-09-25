json.payload do
  json.array! @articles.includes([:category, :associated_articles, { author: { avatar_attachment: [:blob] } }]),
              partial: 'public/api/v1/models/article', formats: [:json], as: :article
end

json.meta do
  json.articles_count @articles_count
end
