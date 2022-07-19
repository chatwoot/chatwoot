class Public::Api::V1::Portals::CategoriesController < PublicController
  before_action :set_portal
  before_action :set_category, only: [:show]

  def index
    @categories = @portal.categories
  end

  def show; end

  private

  def set_category
    @category = @portal.categories.find_by!(slug: params[:slug])
  end

  def set_portal
    @portal = ::Portal.find_by!(slug: params[:portal_slug], archived: false)
  end
end
