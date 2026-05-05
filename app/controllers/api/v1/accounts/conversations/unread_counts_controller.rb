class Api::V1::Accounts::Conversations::UnreadCountsController < Api::V1::Accounts::BaseController
  def index
    counts = ::Conversations::UnreadCounts::Counter.new(account: Current.account, user: Current.user).perform
    render json: { payload: counts }
  end
end
