class Api::V1::Accounts::Integrations::GithubController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    @github_integration = Current.account.hooks.find_by(app_id: 'github')
  end

  private

  def check_authorization
    authorize ::Webhook, :show?
  end
end