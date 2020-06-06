class Api::V1::Accounts::SubscriptionsController < Api::V1::Accounts::BaseController
  skip_before_action :check_subscription

  before_action :check_billing_enabled

  def index
    render json: Current.account.subscription_data
  end

  def status
    render json: Current.account.subscription.summary
  end
end
