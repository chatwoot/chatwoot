class Integrations::Zalo::Auth

  def verify(code:, code_verifier:)
    code = code.presence || raise('Code is required')
    code_verifier = code_verifier.presence || raise('Code verifier is required')

    unauthenticated_client(
      code: code,
      code_verifier: code_verifier,
      grant_type: :authorization_code,
    )
  end

  def refresh_access_token(token)
    token = token.presence || raise('Refresh token is required')

    unauthenticated_client(
      refresh_token: token,
      grant_type: :refresh_token,
    )
  end

  private

  def unauthenticated_client(data = {})
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'secret_key' => Integrations::Zalo::Constants.app_secret!,
    }
    default_body = {
      app_id: Integrations::Zalo::Constants.app_id!,
    }
    Integrations::Zalo::Client
      .new('https://oauth.zaloapp.com/v4/oa/access_token')
      .urlencoded!
      .headers(headers)
      .body(default_body.merge(data))
      .post
  end
end
