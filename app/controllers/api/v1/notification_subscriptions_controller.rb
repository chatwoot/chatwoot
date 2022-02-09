class Api::V1::NotificationSubscriptionsController < Api::BaseController
  before_action :set_user

  def create
    notification_subscription = NotificationSubscriptionBuilder.new(user: @user, params: notification_subscription_params).perform

    render json: notification_subscription
  end

  def destroy
    notification_subscription = NotificationSubscription.where(["subscription_attributes->>'push_token' = ?", params[:push_token]]).first
    notification_subscription.destroy
    head :ok
  end

  private

  def set_user
    @user = current_user
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end
end
