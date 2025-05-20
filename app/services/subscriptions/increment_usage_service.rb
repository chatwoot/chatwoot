class Subscriptions::IncrementUsageService
  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    usage = find_or_create_usage
    return unless usage

    if usage.exceeded_limits?
      log_mau_limit_reached(usage)
    else
      usage.increment_mau
      notify_mau_threshold_reached(usage) if mau_threshold_reached?(usage)
    end
  end

  private

  def subscription
    @subscription ||= Subscription.find_by(account_id: @conversation.account_id, status: 'active')
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: @conversation.account_id)
  end

  def find_or_create_usage
    SubscriptionUsage.find_or_create_by(subscription_id: subscription.id).tap do |u|
      Rails.logger.warn("⚠️ No subscription or usage found for account #{@conversation.account_id}") unless u
    end
  end

  def mau_threshold_reached?(usage)
    subscription.max_mau + subscription.additional_mau - 10 == usage.mau_count
  end

  def notify_mau_threshold_reached(usage)
    user = User.find_by(id: account_user.user_id)

    SubscriptionNotifierMailer.mau_limit_warning(user, usage.mau_count, subscription.max_mau).deliver_later

    Rails.logger.warn("Sent Notification and Email to account id: #{@conversation.account_id}")
  end

  def log_mau_limit_reached(usage)
    Rails.logger.warn("MAU limit reached for subscription #{usage.subscription_id}")
  end
end
