class Api::V1::Accounts::OauthAuthorizationController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  protected

  def scope
    ''
  end

  def state
    Current.account.to_sgid(expires_in: 15.minutes).to_s
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
