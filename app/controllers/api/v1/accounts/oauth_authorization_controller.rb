class Api::V1::Accounts::OauthAuthorizationController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  protected

  def scope
    ''
  end

  def state
    # The sgid purpose doubles as a return hint: onboarding tags it so the callback
    # can route the user back to inbox setup. The purpose is part of the signed
    # payload (tamper-proof), and a non-onboarding request keeps the default
    # purpose, leaving callers like Notion byte-identical.
    Current.account.to_sgid(expires_in: 15.minutes, for: state_purpose).to_s
  end

  def state_purpose
    params[:return_to] == 'onboarding' ? 'onboarding' : 'default'
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
