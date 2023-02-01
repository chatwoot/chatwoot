class Api::V1::Accounts::SearchController < Api::V1::Accounts::BaseController
  def index
    @result = TextSearch.new(Current.user, Current.account, params).perform
  end
end
