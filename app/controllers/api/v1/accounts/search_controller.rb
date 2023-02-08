class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = TextSearch.new(current_user: Current.user, current_account: Current.account, params: params).perform
  end
end
