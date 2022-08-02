json.payload do
  json.array! @articles, partial: 'article', as: :article
end

json.meta do
  json.current_page @current_page
  json.articles_count @articles_count
end
