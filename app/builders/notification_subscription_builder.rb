class NotificationSubscriptionBuilder
  pattr_initialize [:params, :user!]

  def perform
    # if multiple accounts were used to login in same browser
    move_subscription_to_user if identifier_subscription && identifier_subscription.user_id != user.id
    build_identifier_subscription if identifier_subscription.blank?
    identifier_subscription
  end

  private

  def identifier
    @identifier ||= params[:subscription_attributes][:endpoint] if params[:subscription_type] == 'browser_push'
    @identifier ||= params[:subscription_attributes][:device_id] if params[:subscription_type] == 'fcm'
    @identifier
  end

  def identifier_subscription
    @identifier_subscription ||= NotificationSubscription.find_by(identifier: identifier)
  end

  def move_subscription_to_user
    @identifier_subscription.update(user_id: user.id)
  end

  def build_identifier_subscription
    user.notification_subscriptions.create(params.merge(identifier: identifier))
  end
end
