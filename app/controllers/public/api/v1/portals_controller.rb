class Public::Api::V1::PortalsController < PublicController
  before_action :ensure_custom_domain_request, only: [:show]
  before_action :portal
  layout 'portal'

  def show; end

  private

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
  end
end
