class Api::V1::Accounts::Saml::CallbacksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!

  def create
    @saml_settings = AccountSamlSettings.find_by(account_id: @current_account.id, enabled: true)

    return render_saml_not_enabled unless @saml_settings

    render json: {
      saml_settings: {
        sp_entity_id: @saml_settings.sp_entity_id_or_default,
        enabled: @saml_settings.enabled,
        sso_url: @saml_settings.sso_url,
        certificate_fingerprint: @saml_settings.certificate_fingerprint,
        enforced_sso: @saml_settings.enforced_sso,
        attribute_mappings: @saml_settings.attribute_mappings,
        role_mappings: @saml_settings.role_mappings
      },
      received_data: {
        saml_response: params[:SAMLResponse],
        relay_state: params[:RelayState]
      },
      message: 'SAML callback received successfully'
    }
  end

  def sso
    @saml_settings = AccountSamlSettings.find_by(account_id: @current_account.id, enabled: true)

    return render_saml_not_enabled unless @saml_settings

    render json: {
      sso_url: @saml_settings.sso_url,
      sp_entity_id: @saml_settings.sp_entity_id_or_default,
      acs_url: acs_url,
      certificate_fingerprint: @saml_settings.certificate_fingerprint
    }
  end

  private

  def render_saml_not_enabled
    render json: { error: 'SAML not enabled for this account' }, status: :not_found
  end

  def acs_url
    api_v1_account_saml_callback_url(@current_account)
  end
end
