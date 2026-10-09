class Api::V1::NotificationSubscriptionsController < Api::BaseController
  include MfaEnforcementGuard

  before_action :set_user
  before_action :check_user_mfa_enforcement, if: :authenticate_by_access_token?

  def create
    return render_could_not_create_error(I18n.t('errors.notification_subscription.voip_attributes_required')) if voip_attributes_missing?

    notification_subscription = NotificationSubscriptionBuilder.new(user: @user, params: notification_subscription_params).perform

    render json: notification_subscription
  end

  # A phone keeps an FCM row and, on iOS, a VoIP row keyed on the same device; removing
  # either token removes both, so a signed-out iPhone stops ringing even when only one
  # token is sent
  def destroy
    notification_subscription = current_user.notification_subscriptions
                                            .where(["subscription_attributes->>'push_token' = ?", params[:push_token]]).first
    return head :ok if notification_subscription.blank?

    device_rows(notification_subscription).destroy_all
    head :ok
  end

  private

  def set_user
    @user = current_user
  end

  def device_rows(subscription)
    return NotificationSubscription.where(id: subscription.id) unless subscription.fcm? || subscription.apns_voip?

    device_id = subscription.identifier.delete_prefix('voip:')
    current_user.notification_subscriptions.where(subscription_type: %w[fcm apns_voip], identifier: [device_id, "voip:#{device_id}"])
  end

  # A VoIP row is keyed on the device and carries the token that rings it: without the
  # device id it would be shared by everyone, and without the token it would erase the
  # one the device already registered
  def voip_attributes_missing?
    return false unless notification_subscription_params[:subscription_type] == 'apns_voip'

    attributes = notification_subscription_params[:subscription_attributes] || {}
    [attributes[:device_id], attributes[:push_token]].any? { |value| !value.is_a?(String) || value.blank? }
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end
end
