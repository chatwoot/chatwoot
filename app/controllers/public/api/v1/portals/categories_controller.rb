class Public::Api::V1::Portals::CategoriesController < PublicController
  before_action :ensure_custom_domain_request, only: [:show, :index]
  before_action :set_portal
  before_action :set_category, only: [:show]
  layout 'portal'

  def index
    @categories = @portal.categories
  end

  def show; end

  private

  def set_category
    @category = @portal.categories.find_by!(locale: params[:locale], slug: params[:category_slug])
  end

  def set_portal
    @portal = @portals.find_by!(slug: params[:slug], archived: false)
  end
end
