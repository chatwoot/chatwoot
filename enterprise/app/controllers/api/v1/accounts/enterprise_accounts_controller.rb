class Api::V1::Accounts::EnterpriseAccountsController < Api::V1::Accounts::BaseController
  private

  def check_authorization
    authorize(Current.account)
  end
end
