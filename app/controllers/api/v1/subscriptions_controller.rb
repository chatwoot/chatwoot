class Api::V1::SubscriptionsController < Api::BaseController
  skip_before_action :check_subscription

  before_action :check_billing_enabled

  def index
    render json: current_account.subscription_data
  end

  def status
    render json: current_account.subscription.summary
  end
end
