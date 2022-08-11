class Public::Api::V1::PortalsController < PublicController
  before_action :ensure_custom_domain_request, only: [:show]
  before_action :set_portal

  def show; end

  private

  def set_portal
    @portal = @portals.find_by!(slug: params[:slug], archived: false)
  end
end
