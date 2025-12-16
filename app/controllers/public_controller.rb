# TODO: we should switch to ActionController::API for the base classes
# One of the specs is failing when I tried doing that, lets revisit in future
class PublicController < ActionController::Base
  include RequestExceptionHandler
  include BillingHelper
  skip_before_action :verify_authenticity_token

  private

  def ensure_custom_domain_request
    domain = request.host
    return if DomainHelper.chatwoot_domain?(domain)

    @portal = ::Portal.find_by(custom_domain: domain)

    if @portal.blank?
      render json: {
        error: "Domain: #{domain} is not registered with us. \
        Please send us an email at support@chatwoot.com with the custom domain name and account API key"
      }, status: :unauthorized and return
    end

    check_portal_plan_access
  end

  def check_portal_plan_access
    return unless ChatwootApp.chatwoot_cloud?

    # Handle both custom domain (@portal) and regular slug-based access (portal method)
    current_portal = @portal
    if current_portal.blank? && respond_to?(:portal, true)
      begin
        current_portal = portal
      rescue ActiveRecord::RecordNotFound
        return # Let the normal 404 handling take care of this
      end
    end

    return if current_portal.blank?
    return unless default_plan?(current_portal.account)

    render 'public/api/v1/portals/not_active', status: :payment_required
  end
end
