# The iPhone VoIP token that rings phones for calls: registered as its own subscription,
# and removed together with the phone's FCM row
module Enterprise::Api::V1::NotificationSubscriptionsController
  def create
    return render_could_not_create_error(I18n.t('errors.notification_subscription.voip_attributes_required')) if voip_attributes_missing?

    super
  end

  # A phone keeps an FCM row and, on iOS, a VoIP row keyed on the same device; removing
  # either token removes both, so a signed-out iPhone stops ringing even when only one
  # token is sent
  def destroy
    subscription = current_user.notification_subscriptions.where(["subscription_attributes->>'push_token' = ?", params[:push_token]]).first
    return super unless subscription&.fcm? || subscription&.apns_voip?

    device_id = subscription.identifier.delete_prefix('voip:')
    current_user.notification_subscriptions.where(subscription_type: %w[fcm apns_voip], identifier: [device_id, "voip:#{device_id}"]).destroy_all
    head :ok
  end

  private

  # A VoIP row is keyed on the device and carries the token that rings it: without the
  # device id it would be shared by everyone, and without the token it would erase the
  # one the device already registered
  def voip_attributes_missing?
    return false unless notification_subscription_params[:subscription_type] == 'apns_voip'

    attributes = notification_subscription_params[:subscription_attributes] || {}
    [attributes[:device_id], attributes[:push_token]].any? { |value| !value.is_a?(String) || value.blank? }
  end
end
