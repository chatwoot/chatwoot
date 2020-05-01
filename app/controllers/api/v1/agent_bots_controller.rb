class Api::V1::AgentBotsController < Api::BaseController
  skip_before_action :authenticate_user!
  skip_before_action :check_subscription

  def index
    render json: AgentBot.all
  end
end
