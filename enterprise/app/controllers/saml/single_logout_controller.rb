class Saml::SingleLogoutController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_forgery_protection

  def create
    return head :not_found unless saml_available?

    @service = Saml::SingleLogoutService.new(
      saml_settings: saml_settings,
      encoded_request: params[:SAMLRequest],
      relay_state: params[:RelayState]
    )
    request_id = @service.perform
    redirect_with_logout_response(request_id, Saml::SingleLogoutService::STATUS_SUCCESS, 'Successfully signed out')
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    head :not_found
  rescue Saml::SingleLogoutService::ConfigurationError
    head :unprocessable_entity
  rescue Saml::SingleLogoutService::ReplayDetected, Saml::SingleLogoutService::UnknownPrincipal => e
    redirect_with_logout_response(e.request_id, Saml::SingleLogoutService::STATUS_REQUESTER, e.message)
  rescue Saml::SingleLogoutService::InvalidRequest
    head :bad_request
  end

  private

  def saml_settings
    @saml_settings ||= AccountSamlSettings.find_signed!(
      params[:settings_token],
      purpose: AccountSamlSettings::SINGLE_LOGOUT_SIGNED_ID_PURPOSE
    )
  end

  def saml_available?
    return false unless GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s == 'true'

    saml_settings.account.feature_enabled?('saml')
  end

  def redirect_with_logout_response(request_id, status_code, message)
    response_url = @service.logout_response_url(request_id: request_id, status_code: status_code, message: message)
    redirect_to response_url, allow_other_host: true
  end
end
