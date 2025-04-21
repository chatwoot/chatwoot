class Api::V1::Accounts::Integrations::GithubController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:destroy]

  def destroy
    @hook.destroy!
    head :ok
  end

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'github')
  end
end
