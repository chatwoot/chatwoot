class Api::V1::NotificationSubscriptionsController < Api::BaseController
  before_action :set_user

  def create
    notification_subscription = NotificationSubscriptionBuilder.new(user: @user, params: notification_subscription_params).perform

    render json: notification_subscription
  end

  def destroy
    notification_subscription = NotificationSubscription.where(["subscription_attributes->>'push_token' = ?", params[:push_token]]).first
    notification_subscription.destroy! if notification_subscription.present?
    head :ok
  end

  private

  def set_user
    @user = current_user
  end

  def notification_subscription_params
    raw_params = params[:notification_subscription] || params
    permitted_params = if raw_params.is_a?(ActionController::Parameters)
                         raw_params
                       else
                         ActionController::Parameters.new(raw_params)
                       end

    permitted_params.permit(:subscription_type, subscription_attributes: {})
  end
end
