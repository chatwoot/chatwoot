class CustomDomainsController < ApplicationController
  def verify
    challenge_id = permitted_params[:id]

    domain = request.host
    portal = Portal.find_by(custom_domain: domain)

    return render plain: 'Domain not found', status: :not_found unless portal

    ssl_settings = portal.ssl_settings || {}

    return render plain: 'Challenge ID not found', status: :not_found unless ssl_settings['cf_verification_id'] == challenge_id

    render plain: ssl_settings['cf_verification_body'], status: :ok
  end

  private

  def permitted_params
    params.permit(:id)
  end
end
