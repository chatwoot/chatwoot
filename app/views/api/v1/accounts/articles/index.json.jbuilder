json.payload do
  json.array! @articles, partial: 'article', as: :article
end

json.meta do
  json.all_articles_count @portal_articles.size
  json.archived_articles_count @articles.archived.size
  json.articles_count @articles_count
  json.current_page @current_page
  json.draft_articles_count @draft_count
  json.mine_articles_count @mine_count
  json.published_count @published_count
end
