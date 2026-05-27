class Api::V1::Accounts::Articles::BulkActionsController < Api::V1::Accounts::BaseController
  before_action :portal
  before_action :check_authorization
  before_action :set_articles, only: [:update_status, :update_category, :delete_articles]

  def translate
    head :not_implemented
  end

  def update_status
    return render_could_not_create_error(I18n.t('portals.articles.no_articles_found')) if @articles.none?
    return render_could_not_create_error(I18n.t('portals.articles.invalid_status')) unless Article.statuses.key?(params[:status])

    ActiveRecord::Base.transaction do
      @articles.find_each { |article| article.update!(status: params[:status]) }
    end
    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.message)
  end

  def update_category
    return render_could_not_create_error(I18n.t('portals.articles.no_articles_found')) if @articles.none?
    return render_could_not_create_error(I18n.t('portals.articles.category_not_found')) unless category_valid?

    ActiveRecord::Base.transaction do
      @articles.find_each { |article| article.update!(category_id: params[:category_id]) }
    end
    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.message)
  end

  def delete_articles
    return render_could_not_create_error(I18n.t('portals.articles.no_articles_found')) if @articles.none?

    @articles.destroy_all
    head :ok
  end

  private

  def portal
    @portal ||= Current.account.portals.find_by!(slug: params[:portal_id])
  end

  def check_authorization
    authorize(Article, :create?)
  end

  def set_articles
    @articles = @portal.articles.where(id: params[:ids])
  end

  def category_valid?
    @portal.categories.exists?(id: params[:category_id])
  end
end
Api::V1::Accounts::Articles::BulkActionsController.prepend_mod_with('Api::V1::Accounts::Articles::BulkActionsController')
