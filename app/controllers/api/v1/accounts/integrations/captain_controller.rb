class Api::V1::Accounts::Integrations::CaptainController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook

  def sso_url
    params_string =
      "token=#{URI.encode_www_form_component(@hook['settings']['access_token'])}" \
      "&email=#{URI.encode_www_form_component(@hook['settings']['account_email'])}" \
      "&account_id=#{URI.encode_www_form_component(@hook['settings']['account_id'])}"

    installation_config = InstallationConfig.find_by(name: 'CAPTAIN_APP_URL')

    sso_url = "#{installation_config.value}/sso?#{params_string}"
    render json: { sso_url: sso_url }, status: :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'captain')
  end
end
