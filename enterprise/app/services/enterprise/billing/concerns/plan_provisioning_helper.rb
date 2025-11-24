module Enterprise::Billing::Concerns::PlanProvisioningHelper
  extend ActiveSupport::Concern

  private

  def provision_new_plan(new_pricing_plan_id)
    plan_definition = Enterprise::Billing::V2::PlanCatalog.definition_for(new_pricing_plan_id)
    return unless plan_definition

    plan_name = plan_definition[:display_name]
    enable_plan_specific_features(plan_name) if plan_name.present?
  end
end
