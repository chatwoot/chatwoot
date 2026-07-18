class Api::V1::Accounts::CallsController < Api::V1::Accounts::EnterpriseAccountsController
  def index
    result = CallFinder.new(Current.user, Current.account, params).perform
    @calls = result[:calls]
    @calls_count = result[:count]
  end
end
