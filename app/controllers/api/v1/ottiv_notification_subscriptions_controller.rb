class Api::V1::OttivNotificationSubscriptionsController < Api::BaseController
  before_action :set_user

  def create
    subscription_params = notification_subscription_params
    subscription_type = subscription_params[:subscription_type] || 'browser_push'

    identifier = if subscription_type == 'browser_push'
                   subscription_params[:subscription_attributes][:endpoint]
                 elsif subscription_type == 'fcm'
                   subscription_params[:subscription_attributes][:device_id]
                 end

    existing_subscription = OttivNotificationSubscription.find_by(identifier: identifier)

    if existing_subscription
      if existing_subscription.user_id != @user.id
        existing_subscription.update!(user_id: @user.id)
      end
      existing_subscription.update!(
        subscription_type: subscription_type,
        subscription_attributes: subscription_params[:subscription_attributes]
      )
      render json: existing_subscription
    else
      new_subscription = @user.ottiv_notification_subscriptions.create!(
        subscription_type: subscription_type,
        subscription_attributes: subscription_params[:subscription_attributes],
        identifier: identifier
      )
      render json: new_subscription, status: :created
    end
  end

  def destroy
    endpoint = params[:endpoint] ||
               params.dig(:notification_subscription, :subscription_attributes, :endpoint) ||
               params.dig(:subscription_attributes, :endpoint)

    if endpoint.blank?
      endpoint = params[:push_token] ? OttivNotificationSubscription.where(
        ["subscription_attributes->>'push_token' = ?", params[:push_token]]
      ).first&.subscription_attributes&.dig('endpoint') : nil
    end

    if endpoint.blank?
      return render json: { error: 'Endpoint is required' }, status: :bad_request
    end

    notification_subscription = OttivNotificationSubscription.find_by(
      identifier: endpoint,
      subscription_type: 'browser_push'
    )

    if notification_subscription
      notification_subscription.destroy!
      head :ok
    else
      head :not_found
    end
  end

  private

  def set_user
    @user = current_user
  end

  def notification_subscription_params
    params.require(:notification_subscription).permit(:subscription_type, subscription_attributes: {})
  end
end

