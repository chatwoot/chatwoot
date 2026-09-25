class EnableMonitorAndClassifierFeaturesForPaidPlans < ActiveRecord::Migration[7.1]
  FEATURES = %w[conversation_monitors captain_classifier].freeze
  PLAN_NAMES = %w[Startups Business Enterprise].freeze

  def up
    return unless ChatwootApp.chatwoot_cloud?

    preserve_existing_grants

    stripe_accounts = Account.where("custom_attributes->>'plan_name' IN (?)", PLAN_NAMES)
                             .where("COALESCE(NULLIF(internal_attributes->>'billing_provider', ''), 'stripe') = 'stripe'")
    shopify_accounts = Account.where("internal_attributes->>'billing_provider' = 'shopify'")
                              .where("custom_attributes->>'plan_name' <> ''")

    [stripe_accounts, shopify_accounts].each do |scope|
      scope.find_each(batch_size: 100) do |account|
        next if account.billing_provider == 'shopify' && !Shopify::FeatureGate.enabled?(account: account)

        missing_features = FEATURES.reject { |feature| account.feature_enabled?(feature) }
        next if missing_features.empty?

        account.enable_features(*missing_features)
        account.save!(validate: false)
      end
    end
  end

  private

  def preserve_existing_grants
    # Before the features become plan-managed, retain existing pilot grants
    # as manual overrides so a later reconciliation does not revoke them.
    FEATURES.each do |feature|
      Account.public_send("feature_#{feature}").find_each(batch_size: 100) do |account|
        next if account.billing_provider == 'shopify' && Array(account.internal_attributes['shopify_managed_features']).include?(feature)

        manual_features = Array(account.internal_attributes['manually_managed_features'])
        next if manual_features.include?(feature)

        account.internal_attributes = account.internal_attributes.merge('manually_managed_features' => manual_features | [feature])
        account.save!(validate: false)
      end
    end
  end
end
