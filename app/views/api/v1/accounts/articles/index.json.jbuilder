json.payload do
  json.array! @articles, partial: 'article', as: :article
end

json.meta do
  json.current_page @current_page
  json.articles_count @articles_count
  json.mine_articles_count @all_articles.search_by_author(current_user.id).size if current_user.present?
  json.all_articles_count @portal_articles.size
  json.draft_articles_count @all_articles.draft.size
end
