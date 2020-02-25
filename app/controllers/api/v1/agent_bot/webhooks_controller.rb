class Api::V1::AgentBot::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  skip_before_action :check_subscription

  def create
    # TODO: Setup basic auth
    # TODO Use builder based on the bot vendor
    head :ok
  rescue StandardError => e
    Raven.capture_exception(e)
    head :ok
  end
end
