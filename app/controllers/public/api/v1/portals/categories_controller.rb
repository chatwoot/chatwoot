class Public::Api::V1::Portals::CategoriesController < Public::Api::V1::Portals::BaseController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :portal
  before_action :set_category, only: [:show]
  after_action :allow_iframe_requests

  layout 'portal'

  def index
    @categories = @portal.categories.order(position: :asc)
  end

  def show; end

  private

  def set_category
    @category = @portal.categories.find_by!(locale: params[:locale], slug: params[:category_slug])
  end

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
