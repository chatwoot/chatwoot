class Enterprise::Billing::V2::SubscriptionService < Enterprise::Billing::V2::BaseService
  # rubocop:disable Metrics/MethodLength
  def migrate_to_v2(plan_type: 'startup')
    return { success: false, message: 'Already on V2' } if v2_enabled?

    credits = plan_credits(plan_type)

    with_locked_account do
      update_custom_attributes(
        'stripe_billing_version' => 2,
        'monthly_credits' => credits,
        'topup_credits' => 0,
        'plan_name' => plan_type.capitalize,
        'subscription_status' => 'active'
      )

      log_credit_transaction(
        type: 'grant',
        amount: credits,
        credit_type: 'monthly',
        description: "Initial V2 migration grant - #{plan_type} plan",
        metadata: { 'source' => 'migration', 'plan_type' => plan_type }
      )

      Rails.logger.info "Migrated account #{account.id} to V2 billing with #{plan_type} plan"
    end

    { success: true, message: 'Successfully migrated to V2 billing' }
  rescue StandardError => e
    Rails.logger.error "Failed to migrate account #{account.id} to V2: #{e.message}"
    { success: false, message: e.message }
  end
  # rubocop:enable Metrics/MethodLength

  def update_plan(plan_type)
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?

    update_custom_attributes('plan_name' => plan_type.capitalize)

    { success: true, plan: plan_type }
  end

  private

  def plan_credits(plan_type)
    config = Rails.application.config.stripe_v2
    return 100 unless config && config[:plans]

    plan_config = config[:plans][plan_type.to_s.downcase.to_sym]
    plan_config ? plan_config[:monthly_credits] : 100
  end
end
