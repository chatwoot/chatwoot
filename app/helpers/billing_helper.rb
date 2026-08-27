module BillingHelper
  private

  def default_plan?(account)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config&.value&.first

    # Return false if not plans are configured, so that no checks are enforced
    return false if default_plan.blank?

    account.custom_attributes['plan_name'].nil? || account.custom_attributes['plan_name'] == default_plan['name']
  end

  def conversations_this_month(account)
    account.conversations.where('created_at > ?', 30.days.ago).count
  end

  def non_web_inboxes(account)
    account.inboxes.where.not(channel_type: Channel::WebWidget.to_s).count
  end

  def agents(account)
    account.users.count
  end

  # current_period_end moved to the subscription item in newer Stripe API versions; read both.
  def subscription_period_end(subscription)
    subscription['current_period_end'] || subscription['items']['data'].first&.[]('current_period_end')
  end

  def subscription_ends_on(subscription)
    period_end = subscription_period_end(subscription)
    return if period_end.blank?

    Time.zone.at(period_end)
  end
end
