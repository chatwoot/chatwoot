class Api::V1::Accounts::SamlSettingsController < Api::V1::Accounts::BaseController
  before_action :check_saml_feature_enabled
  before_action :check_authorization
  before_action :set_saml_settings

  def show; end

  def create
    @saml_settings = Current.account.build_saml_settings(saml_settings_params)
    @saml_settings.save!
  end

  def update
    @saml_settings.update!(saml_settings_params)
  end

  def destroy
    @saml_settings.destroy!
    head :no_content
  end

  private

  def set_saml_settings
    @saml_settings = Current.account.saml_settings || Current.account.build_saml_settings
  end

  def saml_settings_params
    params.require(:saml_settings).permit(
      :enabled,
      :sso_url,
      :certificate_fingerprint,
      :certificate,
      :sp_entity_id,
      :enforced_sso,
      attribute_mappings: {},
      role_mappings: {}
    )
  end

  def check_authorization
    authorize(AccountSamlSettings)
  end

  def check_saml_feature_enabled
    return if Current.account.feature_enabled?('saml')

    render json: { error: 'SAML feature not enabled for this account' }, status: :forbidden
  end
end
