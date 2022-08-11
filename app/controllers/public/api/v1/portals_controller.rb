class Public::Api::V1::PortalsController < PublicController
  before_action :set_portal
  before_action :ensure_custom_domain_request, only: [:show]

  def show; end

  private

  def set_portal
    @portal = @portals.find_by!(slug: params[:slug], archived: false)
  end

  def ensure_custom_domain_request
    custom_domain = request.host

    @portals = ::Portal.where(custom_domain: custom_domain)

    render json: {
      error: "Domain: #{custom_domain} is not registered with us. \
             Please send us an email at support@chatwoot.com with the custom domain name and account API key"
    }, status: :unauthorized if @portals.blank?
  end
end
