module Enterprise::Api::V1::Accounts::Articles::BulkActionsController
  def translate
    return unless validate_translate_params?

    @articles.find_each do |article|
      Captain::Articles::TranslateJob.perform_later(
        Current.account, article.id, @locale, @category.id, Current.user
      )
    end

    head :ok
  end

  private

  def permitted_params
    params.permit(:locale, :category_id, ids: [])
  end

  def validate_translate_params?
    @locale = permitted_params[:locale]
    @category = @portal.categories.find_by(id: permitted_params[:category_id])
    @articles = @portal.articles.where(id: permitted_params[:ids])

    valid_locale? && valid_category? && valid_articles?
  end

  def valid_locale?
    return true if @portal.config['allowed_locales']&.include?(@locale)

    render_could_not_create_error(I18n.t('portals.articles.locale_not_available'))
    false
  end

  def valid_category?
    return true if @category.present?

    render_could_not_create_error(I18n.t('portals.articles.category_not_found'))
    false
  end

  def valid_articles?
    return true if @articles.any?

    render_could_not_create_error(I18n.t('portals.articles.no_articles_found'))
    false
  end
end
