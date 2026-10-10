class Api::V1::NotificationSubscriptionsController < Api::BaseController
  include MfaEnforcementGuard

  before_action :set_user
  before_action :check_user_mfa_enforcement, if: :authenticate_by_access_token?

  def create
    notification_subscription = NotificationSubscriptionBuilder.new(user: @user, params: notification_subscription_params).perform

    render json: notification_subscription
  end

  def destroy
    notification_subscription = current_user.notification_subscriptions
                                            .where(["subscription_attributes->>'push_token' = ?", params[:push_token]]).first
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
end
