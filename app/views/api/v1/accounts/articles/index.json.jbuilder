json.payload do
  json.array! @articles, partial: 'article', as: :article
end

json.meta do
  json.current_page @current_page
  json.articles_count @articles_count
  json.all_articles_count @articles_count
  json.archived_articles_count @articles.archived.size
  json.published_count @articles.published.size
  json.draft_articles_count @articles.draft.size
  json.mine_articles_count @articles.search_by_author(current_user.id).size if current_user.present?
end
