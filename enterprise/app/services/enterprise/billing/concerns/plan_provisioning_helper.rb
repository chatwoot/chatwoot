module Enterprise::Billing::Concerns::PlanProvisioningHelper
  extend ActiveSupport::Concern

  private

  def provision_new_plan(new_pricing_plan_id)
    sync_plan_credits(new_pricing_plan_id)

    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(new_pricing_plan_id)
    if plan_definition
      plan_name = extract_plan_name(plan_definition)
      enable_plan_specific_features(plan_name) if plan_name.present?
    end

    reset_captain_usage
  end

  def sync_plan_credits(pricing_plan_id)
    plan_credits = Enterprise::Billing::V2::PlanCatalog.monthly_credits_for(pricing_plan_id)

    Enterprise::Billing::V2::CreditManagementService
      .new(account: account)
      .sync_monthly_credits(plan_credits.to_i)
  end

  def extract_plan_name(plan_definition)
    plan_definition[:display_name].split.find { |word| %w[Startup Startups Business Enterprise].include?(word) }
  end

  def update_account_plan(new_pricing_plan_id, quantity, next_billing_date)
    attributes = {
      'stripe_pricing_plan_id' => new_pricing_plan_id,
      'pending_stripe_pricing_plan_id' => nil,
      'pending_subscription_quantity' => nil,
      'subscribed_quantity' => quantity,
      'next_billing_date' => next_billing_date
    }

    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(new_pricing_plan_id)
    attributes['plan_name'] = plan_definition[:display_name] if plan_definition

    update_custom_attributes(attributes)
  end
end
