class Public::Api::V1::Portals::CategoriesController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :portal
  before_action :set_portal_layout
  before_action :set_view_variant
  before_action :ensure_portal_feature_enabled
  before_action :set_category, only: [:show]
  before_action :load_category_articles, only: [:show], if: -> { @portal_layout == 'documentation' }
  layout 'portal'

  def index
    respond_to do |format|
      format.html { redirect_to public_portal_locale_path(@portal.slug, params[:locale]), status: :moved_permanently }
      format.json { @categories = @portal.categories.order(position: :asc) }
    end
  end

  def show
    set_locale_switch_urls
    @og_image_url = helpers.set_og_image_url(@portal.name, @category.name)
  end

  private

  def set_category
    @category = @portal.categories.find_by(locale: params[:locale], slug: params[:category_slug])

    Rails.logger.info "Category: not found for slug: #{params[:category_slug]}"
    render_404 && return if @category.blank?
  end

  def set_locale_switch_urls
    categories = @category.translation_family.includes(:portal)

    @locale_switch_urls = categories.to_h do |category|
      [category.locale, helpers.public_category_path(category, **locale_switch_url_options)]
    end
  end

  def load_category_articles
    @articles = @category.articles.published.order(:position).includes(:author)
    @category_authors = @articles.filter_map(&:author).uniq
  end
end
