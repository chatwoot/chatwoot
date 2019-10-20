class SubscriptionListener < BaseListener
  def subscription_created(event)
    subscription = event.data[:subscription]
    account = subscription.account
    Subscription::ChargebeeService.create_subscription(account)
  end

  def account_destroyed(event)
    account = event.data[:account]
    Subscription::ChargebeeService.cancel_subscription(account)
  end

  def agent_added(event)
    account = event.data[:account]
    Subscription::ChargebeeService.update_subscription(account)
  end

  def agent_removed(event)
    account = event.data[:account]
    Subscription::ChargebeeService.update_subscription(account)
  end

  def subscription_reactivated(event)
    account = event.data[:account]
    Subscription::ChargebeeService.reactivate_subscription(account)
  end

  def subscription_deactivated(event)
    account = event.data[:account]
    Subscription::ChargebeeService.deactivate_subscription(account)
  end
end
