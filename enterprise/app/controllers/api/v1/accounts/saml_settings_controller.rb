class Api::V1::Accounts::SamlSettingsController < Api::V1::Accounts::BaseController
  before_action :check_saml_feature_enabled
  before_action :check_authorization
  before_action :set_saml_settings

  def show; end

  def create
    @saml_settings = Current.account.build_saml_settings(saml_settings_params)
    if @saml_settings.save
      render :show
    else
      render json: { errors: @saml_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @saml_settings.update(saml_settings_params)
      render :show
    else
      render json: { errors: @saml_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @saml_settings.destroy!
    head :no_content
  end

  private

  def set_saml_settings
    @saml_settings = Current.account.saml_settings ||
                     Current.account.build_saml_settings
  end

  def saml_settings_params
    params.require(:saml_settings).permit(
      :sso_url,
      :certificate,
      :idp_entity_id,
      :sp_entity_id,
      role_mappings: {}
    )
  end

  def check_authorization
    authorize(AccountSamlSettings)
  end

  def check_saml_feature_enabled
    return if Current.account.feature_enabled?('saml')

    render json: { error: I18n.t('errors.saml.feature_not_enabled') }, status: :forbidden
  end
end
