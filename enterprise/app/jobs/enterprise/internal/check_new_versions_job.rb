module Enterprise::Internal::CheckNewVersionsJob
  def perform(refresh_billing: false)
    super(refresh_billing: refresh_billing)
    update_plan_info
    reconcile_premium_config_and_features
  end

  private

  def update_plan_info
    return if @instance_info.blank?

    update_installation_config(key: 'INSTALLATION_PRICING_PLAN', value: @instance_info['plan'])
    update_installation_config(key: 'INSTALLATION_PRICING_PLAN_QUANTITY', value: @instance_info['plan_quantity'])
    update_subscription_status
    update_installation_config(key: 'CHATWOOT_SUPPORT_WEBSITE_TOKEN', value: @instance_info['chatwoot_support_website_token'])
    update_installation_config(key: 'CHATWOOT_SUPPORT_IDENTIFIER_HASH', value: @instance_info['chatwoot_support_identifier_hash'])
    update_installation_config(key: 'CHATWOOT_SUPPORT_SCRIPT_URL', value: @instance_info['chatwoot_support_script_url'])
  end

  def update_subscription_status
    # Missing on older Hub versions; omission is not evidence of recovery.
    return unless @instance_info.key?('subscription_status')

    previous_status = ChatwootHub.subscription_status
    update_installation_config(key: 'INSTALLATION_SUBSCRIPTION_STATUS', value: @instance_info['subscription_status'])
    return if ChatwootApp.chatwoot_cloud? || previous_status == @instance_info['subscription_status']

    # Publish directly instead of one job per account; dashboards drop events without their own account_id.
    Account.ids.each do |account_id|
      ActionCable.server.broadcast("account_#{account_id}", { event: 'account.billing_updated', data: { account_id: account_id } })
    end
  end

  def update_installation_config(key:, value:)
    config = InstallationConfig.find_or_initialize_by(name: key)
    config.value = value
    config.locked = true
    config.save!
  end

  def reconcile_premium_config_and_features
    Internal::ReconcilePlanConfigService.new.perform
  end
end
