class Integrations::Zalo::Auth
  def initialize(code:, code_verifier:)
    @code = code.presence || raise('Code is required')
    @code_verifier = code_verifier.presence || raise('Code verifier is required')
  end

  def verify
    Integrations::Zalo::Client.new('https://oauth.zaloapp.com/v4/oa/access_token')
                              .headers(headers)
                              .body(body)
                              .post
  end

  private

  attr_reader :code, :code_verifier

  def headers
    {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'secret_key' => Integrations::Zalo::Constants.app_secret!
    }
  end

  def body
    {
      code: code,
      code_verifier: code_verifier,
      grant_type: :authorization_code,
      app_id: Integrations::Zalo::Constants.app_id!
    }
  end
end
