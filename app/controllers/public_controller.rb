# TODO: we should switch to ActionController::API for the base classes
# One of the specs is failing when I tried doing that, lets revisit in future
class PublicController < ActionController::Base
  include RequestExceptionHandler
  skip_before_action :verify_authenticity_token

  private

  def ensure_custom_domain_request
    custom_domain = request.host

    @portals = ::Portal.where(custom_domain: custom_domain)

    return if @portals.present?

    render json: {
      error: "Domain: #{custom_domain} is not registered with us. \
      Please send us an email at support@chatwoot.com with the custom domain name and account API key"
    }, status: :unauthorized and return
  end
end
