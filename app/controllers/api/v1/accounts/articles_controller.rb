class Api::V1::Accounts::ArticlesController < Api::V1::Accounts::BaseController
  before_action :portal
  before_action :check_authorization
  before_action :fetch_article, except: [:index, :create, :attach_file]
  before_action :set_current_page, only: [:index]

  def index
    @portal_articles = @portal.articles
    @all_articles = @portal_articles.search(list_params)
    @articles_count = @all_articles.count
    @articles = @all_articles.order_by_updated_at.page(@current_page)
  end

  def create
    @article = @portal.articles.create!(article_params)
    @article.associate_root_article(article_params[:associated_article_id])
    @article.draft!
    process_attached_background_image
    render json: { error: @article.errors.messages }, status: :unprocessable_entity and return unless @article.valid?
  end

  def edit; end

  def show; end

  def update
    @article.update!(article_params) if params[:article].present?
    process_attached_background_image
  end

  def destroy
    @article.destroy!
    head :ok
  end

  def attach_file
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:background_image].tempfile,
      filename: params[:background_image].original_filename,
      content_type: params[:background_image].content_type
    )
    render json: { blob_key: file_blob.key, blob_id: file_blob.id }
  end

  private

  def process_attached_background_image
    blob_id = params[:blob_id]
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    @article.background_image.attach(blob)
  end

  def fetch_article
    @article = @portal.articles.find(params[:id])
  end

  def portal
    @portal ||= Current.account.portals.find_by!(slug: params[:portal_id])
  end

  def article_params
    params.require(:article).permit(
      :title, :slug, :content, :description, :position, :category_id, :author_id, :associated_article_id, :status, meta: [:title, :description,
                                                                                                                          { tags: [] }]
    )
  end

  def list_params
    params.permit(:locale, :query, :page, :category_slug, :status, :author_id)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
