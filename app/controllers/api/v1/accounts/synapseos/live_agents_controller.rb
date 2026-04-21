class Api::V1::Accounts::Synapseos::LiveAgentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @agents = ::Synapseos::LiveAgentsMetricsService.new(Current.account).call
  end

  private

  def check_authorization
    authorize(User, :index?)
  end
end
