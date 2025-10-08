class Enterprise::Billing::V2::SubscriptionService < Enterprise::Billing::V2::BaseService
  def migrate_to_v2(plan_type: 'startup')
    return { success: false, message: 'Already on V2' } if v2_enabled?

    with_locked_account do
      apply_migration_attributes(plan_type)
      log_migration_grant(plan_type)
    end

    { success: true, message: 'Successfully migrated to V2 billing' }
  rescue StandardError => e
    { success: false, message: e.message }
  end

  def update_plan(plan_type)
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?

    update_custom_attributes('plan_name' => plan_type.capitalize)

    { success: true, plan: plan_type }
  end

  private

  def apply_migration_attributes(plan_type)
    credits = plan_credits(plan_type)
    update_custom_attributes(
      'stripe_billing_version' => 2,
      'monthly_credits' => credits,
      'topup_credits' => 0,
      'plan_name' => plan_type.capitalize,
      'subscription_status' => 'active'
    )
  end

  def log_migration_grant(plan_type)
    credits = plan_credits(plan_type)
    log_credit_transaction(
      type: 'grant',
      amount: credits,
      credit_type: 'monthly',
      description: "Initial V2 migration grant - #{plan_type} plan",
      metadata: { 'source' => 'migration', 'plan_type' => plan_type }
    )
  end

  def plan_credits(plan_type)
    config = Rails.application.config.stripe_v2
    return 100 unless config && config[:plans]

    plan_config = config[:plans][plan_type.to_s.downcase.to_sym]
    plan_config ? plan_config[:monthly_credits] : 100
  end
end
