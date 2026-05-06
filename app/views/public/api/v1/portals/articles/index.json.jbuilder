json.payload do
  if @search_query.present?
    json.array! @articles,
                partial: 'public/api/v1/models/search_article',
                formats: [:json],
                as: :article,
                locals: { portal_slug: @portal.slug, search_query: @search_query }
  else
    json.array! @articles.includes([:category, :associated_articles, { author: { avatar_attachment: [:blob] } }]),
                partial: 'public/api/v1/models/article', formats: [:json], as: :article
  end
end

json.meta do
  json.articles_count @articles_count
end
