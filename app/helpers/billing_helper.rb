module BillingHelper
  private

  def default_plan?(account)
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    default_plan = installation_config.value.first
    account.custom_attributes['plan_name'] == default_plan['name']
  end

  def conversations_this_month(account)
    account.conversations.where('created_at > ?', Time.zone.now.beginning_of_month).count
  end

  def non_web_inboxes(account)
    account.inboxes.where.not(channel_type: Channel::WebWidget.to_s).count
  end
end
