class Api::V1::SubscriptionsController < ApplicationController
  skip_before_action :check_subscription

  def index
    render json: current_account.subscription_data
  end

  def status
    render json: current_account.subscription.summary
  end
end
