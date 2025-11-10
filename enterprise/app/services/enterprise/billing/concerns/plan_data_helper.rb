module Enterprise::Billing::Concerns::PlanDataHelper
  extend ActiveSupport::Concern

  private

  def fetch_plan_version(plan_id)
    plan = retrieve_pricing_plan(plan_id)
    version = extract_attribute(plan, :latest_version)
    raise StandardError, "No version found for pricing plan #{plan_id}" if version.blank?

    version
  end

  def fetch_plan_lookup_key(plan_id)
    lookup_key = Enterprise::Billing::V2::PlanCatalog.lookup_key_for_plan(plan_id)
    raise StandardError, "Lookup key not found for pricing plan #{plan_id}" unless lookup_key

    lookup_key
  end

  def plan_display_name(plan_id)
    Enterprise::Billing::V2::PlanCatalog.definition_for(plan_id)&.dig(:display_name) || 'Unknown Plan'
  end
end
