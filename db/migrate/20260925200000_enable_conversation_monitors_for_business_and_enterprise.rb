class EnableConversationMonitorsForBusinessAndEnterprise < ActiveRecord::Migration[7.1]
  FEATURE = 'conversation_monitors'.freeze
  PLAN_NAMES = %w[Business Enterprise].freeze

  def up
    return unless ChatwootApp.chatwoot_cloud?

    # Before the feature becomes plan-managed, retain existing Stripe pilot grants
    # as manual overrides so a later reconciliation does not revoke them.
    Account.feature_conversation_monitors.find_each(batch_size: 100) do |account|
      next unless account.billing_provider == Account::DEFAULT_BILLING_PROVIDER

      manual_features = Array(account.internal_attributes['manually_managed_features'])
      next if manual_features.include?(FEATURE)

      account.internal_attributes = account.internal_attributes.merge('manually_managed_features' => manual_features | [FEATURE])
      account.save!(validate: false)
    end

    Account.where("custom_attributes->>'plan_name' IN (?)", PLAN_NAMES).find_each(batch_size: 100) do |account|
      next unless account.billing_provider == Account::DEFAULT_BILLING_PROVIDER
      next if account.feature_enabled?(FEATURE)

      account.enable_features(FEATURE)
      account.save!(validate: false)
    end
  end
end
