class RepurposeQuotedEmailReplyForBrandedEmailTemplates < ActiveRecord::Migration[7.1]
  def up
    Account.feature_branded_email_templates.find_each(batch_size: 100) do |account|
      account.disable_features(:branded_email_templates)
      account.save!(validate: false)
    end

    remove_stale_default_feature

    if ChatwootApp.chatwoot_cloud?
      reconcile_cloud_business_accounts
    elsif ChatwootApp.self_hosted_enterprise?
      enable_for_self_hosted_enterprise_accounts
      enable_self_hosted_enterprise_default
    end
  end

  private

  def remove_stale_default_feature
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| feature['name'] == 'quoted_email_reply' }
    config.save!
    GlobalConfig.clear_cache
  end

  def reconcile_cloud_business_accounts
    Account.where("custom_attributes->>'plan_name' IN (?)", %w[Business Enterprise]).find_each(batch_size: 100) do |account|
      Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    end
  end

  def enable_for_self_hosted_enterprise_accounts
    Account.find_each(batch_size: 100) do |account|
      account.enable_features!(:branded_email_templates)
    end
  end

  def enable_self_hosted_enterprise_default
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    features = config.value
    feature = features.find { |entry| entry['name'] == 'branded_email_templates' }
    if feature
      feature['enabled'] = true
    else
      features << {
        'name' => 'branded_email_templates',
        'display_name' => 'Branded Email Templates',
        'enabled' => true,
        'premium' => true
      }
    end
    config.update!(value: features)
    GlobalConfig.clear_cache
  end
end
