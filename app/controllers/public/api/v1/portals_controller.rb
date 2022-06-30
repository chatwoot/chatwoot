class Public::Api::V1::PortalsController < PublicController
  before_action :set_portal

  def show; end

  private

  def set_portal
    @portal = ::Portal.find_by!(slug: params[:slug], archived: false)
  end
end
