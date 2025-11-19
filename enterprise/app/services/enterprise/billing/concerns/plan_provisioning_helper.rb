module Enterprise::Billing::Concerns::PlanProvisioningHelper
  extend ActiveSupport::Concern

  private

  def provision_new_plan(new_pricing_plan_id)
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(new_pricing_plan_id)
    return unless plan_definition

    plan_name = extract_plan_name(plan_definition)
    enable_plan_specific_features(plan_name) if plan_name.present?
  end

  def extract_plan_name(plan_definition)
    plan_definition[:display_name].split.find { |word| %w[Startups Business Enterprise].include?(word) }
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
