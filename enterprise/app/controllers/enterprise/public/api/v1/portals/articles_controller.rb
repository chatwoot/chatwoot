module Enterprise::Public::Api::V1::Portals::ArticlesController
  private

  def search_articles
    if @portal.account.feature_enabled?('help_center_embedding_search')
      @articles = @articles.vector_search(list_params) if list_params.present?
    else
      super
    end
  end
end
