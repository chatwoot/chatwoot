class EnableMonitorAndClassifierFeaturesForBusinessAndEnterprise < ActiveRecord::Migration[7.1]
  FEATURES = %w[conversation_monitors captain_classifier].freeze
  PLAN_NAMES = %w[Business Enterprise].freeze

  def up
    return unless ChatwootApp.chatwoot_cloud?

    preserve_existing_grants

    Account.where("custom_attributes->>'plan_name' IN (?)", PLAN_NAMES).find_each(batch_size: 100) do |account|
      next unless account.billing_provider == Account::DEFAULT_BILLING_PROVIDER

      missing_features = FEATURES.reject { |feature| account.feature_enabled?(feature) }
      next if missing_features.empty?

      account.enable_features(*missing_features)
      account.save!(validate: false)
    end
  end

  private

  def preserve_existing_grants
    # Before the feature becomes plan-managed, retain existing Stripe pilot grants
    # as manual overrides so a later reconciliation does not revoke them.
    FEATURES.each do |feature|
      Account.public_send("feature_#{feature}").find_each(batch_size: 100) do |account|
        next unless account.billing_provider == Account::DEFAULT_BILLING_PROVIDER

        manual_features = Array(account.internal_attributes['manually_managed_features'])
        next if manual_features.include?(feature)

        account.internal_attributes = account.internal_attributes.merge('manually_managed_features' => manual_features | [feature])
        account.save!(validate: false)
      end
    end
  end
end
