# frozen_string_literal: true

class Api::V1::Profile::PanelAiSsoController < Api::BaseController
  # Authenticated: returns a one-time Panel AI SSO URL for the current user.
  def create
    panel_url = ENV.fetch('PANEL_AI_PUBLIC_URL', '').to_s.chomp('/')
    if panel_url.blank?
      return render json: { error: 'PANEL_AI_PUBLIC_URL is not configured' }, status: :service_unavailable
    end

    user = Current.user || current_user
    token = user.generate_sso_auth_token
    email = ERB::Util.url_encode(user.email)
    url = "#{panel_url}/login/sso?email=#{email}&sso_auth_token=#{token}"
    render json: { url: url }
  end
end
