module Enterprise::Api::V1::Accounts::Articles::BulkActionsController
  def translate
    return unless validate_translate_params?

    duplicates = find_existing_translations
    if duplicates.any? && !ActiveModel::Type::Boolean.new.cast(permitted_params[:force])
      return render json: {
        duplicate_articles: duplicates.map { |a| { id: a.id, title: a.title } }
      }, status: :conflict
    end

    @articles.find_each do |article|
      Captain::Articles::TranslateJob.perform_later(
        Current.account, article.id, @locale, @category&.id, Current.user
      )
    end

    head :ok
  end

  private

  def permitted_params
    params.permit(:locale, :category_id, :force, ids: [])
  end

  def validate_translate_params?
    @locale = permitted_params[:locale]
    @category = @portal.categories.find_by(id: permitted_params[:category_id], locale: @locale)
    @articles = @portal.articles.where(id: permitted_params[:ids])

    captain_available? && valid_locale? && valid_category? && valid_articles?
  end

  def find_existing_translations
    root_ids = @articles.map { |a| Article.find_root_article_id(a) }
    @portal.articles.where(associated_article_id: root_ids, locale: @locale)
  end

  def captain_available?
    return true if Current.account.feature_enabled?('captain_tasks')

    render_could_not_create_error(I18n.t('portals.articles.captain_not_available'))
    false
  end

  def valid_locale?
    return true if @portal.config['allowed_locales']&.include?(@locale)

    render_could_not_create_error(I18n.t('portals.articles.locale_not_available'))
    false
  end

  def valid_category?
    return true if permitted_params[:category_id].blank?
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
