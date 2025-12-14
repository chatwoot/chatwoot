class Api::V1::Accounts::Integrations::NotionController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:destroy]

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'notion')
  end
end
