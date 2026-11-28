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

    perform_bulk_action('update_status', params[:status])
  end

  def update_category
    return render_could_not_create_error(I18n.t('portals.articles.no_articles_found')) if @articles.none?
    return render_could_not_create_error(I18n.t('portals.articles.category_not_found')) unless category_valid?

    perform_bulk_action('update_category', params[:category_id])
  end

  def delete_articles
    return render_could_not_create_error(I18n.t('portals.articles.no_articles_found')) if @articles.none?

    perform_bulk_action('delete')
  end

  private

  def portal
    @portal ||= Current.account.portals.find_by!(slug: params[:portal_id])
  end

  def check_authorization
    authorize(Article, :create?)
  end

  def set_articles
    @articles = select_all? ? @portal.articles.search(article_filters) : @portal.articles.where(id: params[:ids])
  end

  def select_all?
    ActiveModel::Type::Boolean.new.cast(params[:select_all])
  end

  def article_filters
    params.permit(filters: [:locale, :query, :category_slug, :status, :author_id]).to_h.fetch(:filters, {})
  end

  def perform_bulk_action(action, value = nil)
    if select_all?
      Articles::BulkActionJob.perform_later(@portal, Current.user, @articles.ids, action, value)
      head :accepted
    else
      ActiveRecord::Base.transaction do
        Articles::BulkActionService.new(articles: @articles, action: action, value: value).perform
      end
      head :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.message)
  end

  def category_valid?
    @portal.categories.exists?(id: params[:category_id])
  end
end
Api::V1::Accounts::Articles::BulkActionsController.prepend_mod_with('Api::V1::Accounts::Articles::BulkActionsController')
