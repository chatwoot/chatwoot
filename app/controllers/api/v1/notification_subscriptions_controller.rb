class Api::V1::NotificationSubscriptionsController < Api::BaseController
  include MfaEnforcementGuard

  before_action :set_user
  before_action :check_user_mfa_enforcement, if: :authenticate_by_access_token?

  def create
    return render_could_not_create_error(I18n.t('errors.notification_subscription.device_id_required')) if voip_without_device_id?

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

  # A VoIP row is keyed on the device, so one without a device id would be shared by everyone
  def voip_without_device_id?
    notification_subscription_params[:subscription_type] == 'apns_voip' &&
      notification_subscription_params.dig(:subscription_attributes, :device_id).blank?
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end
end
