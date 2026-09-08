class Saml::SingleLogoutController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_forgery_protection

  def create
    unavailable_reason = saml_unavailable_reason
    return reject_request(:not_found, unavailable_reason) if unavailable_reason

    @service = Saml::SingleLogoutService.new(
      saml_settings: saml_settings,
      encoded_request: params[:SAMLRequest],
      relay_state: params[:RelayState]
    )
    request_id = @service.perform
    redirect_with_logout_response(request_id, Saml::SingleLogoutService::STATUS_SUCCESS, 'Successfully signed out')
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound,
         Saml::SingleLogoutService::ConfigurationError, Saml::SingleLogoutService::ReplayDetected,
         Saml::SingleLogoutService::UnknownPrincipal, Saml::SingleLogoutService::InvalidRequest, Redis::BaseError => e
    handle_rejection(e)
  end

  private

  def saml_settings
    @saml_settings ||= AccountSamlSettings.find_signed!(
      params[:settings_token],
      purpose: AccountSamlSettings::SINGLE_LOGOUT_SIGNED_ID_PURPOSE
    )
  end

  def saml_unavailable_reason
    return 'SAML SSO is globally disabled' unless GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s == 'true'
    return 'SAML feature is disabled for tenant' unless saml_settings.account.feature_enabled?('saml')

    nil
  end

  def redirect_with_logout_response(request_id, status_code, message)
    response_url = @service.logout_response_url(request_id: request_id, status_code: status_code, message: message)
    redirect_to response_url, allow_other_host: true
  end

  def handle_rejection(error)
    case error
    when ActiveSupport::MessageVerifier::InvalidSignature
      reject_request(:not_found, 'settings token is invalid')
    when ActiveRecord::RecordNotFound
      reject_request(:not_found, 'SAML settings were not found')
    when Saml::SingleLogoutService::ConfigurationError
      reject_request(:unprocessable_entity, error.message)
    when Saml::SingleLogoutService::ReplayDetected, Saml::SingleLogoutService::UnknownPrincipal
      log_rejection(error.message)
      redirect_with_logout_response(error.request_id, Saml::SingleLogoutService::STATUS_REQUESTER, error.message)
    when Saml::SingleLogoutService::InvalidRequest
      reject_request(:bad_request, error.message)
    when Redis::BaseError
      reject_request(:service_unavailable, "replay store unavailable: #{error.class.name}")
    end
  end

  def reject_request(status, reason)
    log_rejection(reason)
    head status
  end

  def log_rejection(reason)
    safe_reason = reason.to_s.squish
    Rails.logger.warn("[SAML SLO] Rejected request saml_settings_id=#{@saml_settings&.id || 'unknown'} reason=#{safe_reason}")
  end
end
