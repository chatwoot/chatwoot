namespace :billing do
  desc 'Refresh classifier and monitor entitlements for existing billed accounts'
  task reconcile_classifier_and_monitors: :environment do
    stripe_plans = %w[Hacker Startups Business Enterprise]
    shopify_entitled_states = Shopify::SubscriptionSnapshot::ENTITLED_STATES
    reconciled = 0

    Account.where("custom_attributes->>'plan_name' IS NOT NULL").find_each do |account|
      account.with_lock do
        plan_name = account.custom_attributes['plan_name']
        eligible = if account.billing_provider == 'shopify'
                     account.signup_source == 'shopify' &&
                       shopify_entitled_states.include?(account.custom_attributes['subscription_status']) &&
                       Shopify::FeatureGate.enabled?(account: account)
                   else
                     stripe_plans.include?(plan_name)
                   end
        next unless eligible

        Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
        reconciled += 1
      end
    end

    puts "Reconciled classifier and monitor features for #{reconciled} #{'account'.pluralize(reconciled)}"
  end
end
