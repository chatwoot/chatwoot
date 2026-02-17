class Api::V1::Accounts::X::AuthorizationsController < Api::V1::Accounts::BaseController
  include X::OAuthHelper

  def create
    code_verifier = generate_pkce_verifier
    code_challenge = generate_pkce_challenge(code_verifier)

    state = jwt_encode({
                         sub: Current.account.id,
                         iat: Time.current.to_i,
                         exp: 10.minutes.from_now.to_i,
                         code_verifier: code_verifier
                       })

    client = auth_client
    url = client.auth_code.authorize_url(
      redirect_uri: "#{ENV.fetch('FRONTEND_URL', nil)}/x/callback",
      scope: REQUIRED_SCOPES.join(' '),
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    )

    render json: { authorization_url: url }
  end
end
