# TODO: we should switch to ActionController::API for the base classes
# One of the specs is failing when I tried doing that, lets revisit in future
class PublicController < ActionController::Base
  include RequestExceptionHandler
  skip_before_action :verify_authenticity_token

  private

  def ensure_custom_domain_request
    domain = request.host
    return if DomainHelper.chatwoot_domain?(domain)

    @portal = ::Portal.find_by(custom_domain: domain)
    return if @portal.present?

    render json: {
      error: "Domain: #{domain} is not registered with us. \
      Please send us an email at support@chatwoot.com with the custom domain name and account API key"
    }, status: :unauthorized and return
  end
end
