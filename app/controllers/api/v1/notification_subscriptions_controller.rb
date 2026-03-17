class Api::V1::NotificationSubscriptionsController < Api::BaseController
  before_action :set_user

  def create
    notification_subscription = NotificationSubscriptionBuilder.new(user: @user, params: notification_subscription_params).perform

    render json: notification_subscription
  end

  def destroy
    notification_subscription = find_notification_subscription
    notification_subscription.destroy! if notification_subscription.present?
    head :ok
  end

  private

  def set_user
    @user = current_user
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end

  def find_notification_subscription
    return @user.notification_subscriptions.find_by(["subscription_attributes->>'endpoint' = ?", params[:endpoint]]) if params[:endpoint].present?

    return @user.notification_subscriptions.find_by(["subscription_attributes->>'push_token' = ?", params[:push_token]]) if params[:push_token].present?

    nil
  end
end
