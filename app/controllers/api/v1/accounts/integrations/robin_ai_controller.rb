class Api::V1::Accounts::Integrations::RobinAiController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def generate_sso_url
    response = HTTParty.post(
      ENV.fetch('ROBIN_AI_SSO_URL', ''),
      body: {
        instance_auth_token: ENV.fetch('ROBIN_AI_INSTANCE_AUTH_TOKEN', ''),
        account_id: Current.account.id
      }
    )

    sso_url = response.parsed_response['sso_url']
    render json: { sso_url: sso_url }, status: :ok
  end
end
