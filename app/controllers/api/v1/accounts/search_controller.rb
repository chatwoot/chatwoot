class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = TextSearch.new(current_user: current_user, current_account: current_account, params: params).perform
  end
end
