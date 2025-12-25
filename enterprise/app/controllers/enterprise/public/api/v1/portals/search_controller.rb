module Enterprise::Public::Api::V1::Portals::SearchController
  private

  def search_articles
    if @portal.account.feature_enabled?('help_center_embedding_search')
      @articles = @articles.vector_search(search_params) if @query.present?
    else
      super
    end
  end
end
