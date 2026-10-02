class Api::V1::NotificationSubscriptionsController < Api::BaseController
  include MfaEnforcementGuard

  before_action :set_user
  before_action :check_user_mfa_enforcement, if: :authenticate_by_access_token?

  def create
    return render_could_not_create_error(I18n.t('errors.notification_subscription.voip_attributes_required')) if voip_attributes_missing?

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

  # A VoIP row is keyed on the device and carries the token that rings it: without the
  # device id it would be shared by everyone, and without the token it would erase the
  # one the device already registered
  def voip_attributes_missing?
    return false unless notification_subscription_params[:subscription_type] == 'apns_voip'

    attributes = notification_subscription_params[:subscription_attributes] || {}
    attributes[:device_id].blank? || !attributes[:push_token].is_a?(String) || attributes[:push_token].blank?
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end
end
