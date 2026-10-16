module Enterprise::Public::Api::V1::Portals::SearchController
  private

  def search_articles
    return super if @query.blank? || !@portal.account.feature_enabled?('help_center_embedding_search')

    @articles = @articles.vector_search(search_params.merge(account_id: @portal.account_id, limit: nil))
  end
end
