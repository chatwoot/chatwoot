class Api::V1::Accounts::ArticlesController < Api::V1::Accounts::BaseController
  before_action :portal
  before_action :fetch_article, except: [:index, :create]

  def index
    @articles = @portal.articles
    @articles.search(list_params) if params[:payload].present?
  end

  def create
    @article = @portal.articles.create!(article_params)
  end

  def edit; end

  def show; end

  def update
    @article.update!(article_params)
  end

  def destroy
    @article.destroy!
    head :ok
  end

  private

  def fetch_article
    @article = @portal.articles.find(params[:id])
  end

  def portal
    @portal ||= Current.account.portals.find_by(slug: params[:portal_id])
  end

  def article_params
    params.require(:article).permit(
      :title, :content, :description, :position, :category_id, :author_id
    )
  end

  def list_params
    params.require(:payload).permit(
      :category_slug, :locale, :query
    )
  end
end
