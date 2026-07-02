module Custom::Account::PlanUsageAndLimits
  QUOTA_RESOURCES = %w[teams webhooks agent_bots labels custom_attribute_definitions automation_rules integrations].freeze

  # Fork keys resolve from the per-account limits jsonb only (the same source
  # Custom::EntitlementService enforces from) — no GlobalConfig fallback.
  def usage_limits
    super.merge(QUOTA_RESOURCES.to_h do |resource|
      [resource.to_sym, (self[:limits].to_h[resource].presence || ChatwootApp.max_limit).to_i]
    end)
  end

  private

  # Replaces (not extends) the enterprise implementation because its schema uses
  # `additionalProperties: false`, which rejects the fork's quota keys.
  # Keep the base keys in sync with
  # enterprise/app/models/enterprise/account/plan_usage_and_limits.rb.
  def validate_limit_keys
    errors.add(:limits, ': Invalid data') unless self[:limits].is_a? Hash
    self[:limits] = {} if self[:limits].blank?

    base_keys = %w[inboxes agents captain_responses captain_documents emails]
    limit_schema = {
      'type' => 'object',
      'properties' => (base_keys + QUOTA_RESOURCES).index_with { { 'type': 'number' } },
      'required' => [],
      'additionalProperties' => false
    }

    errors.add(:limits, ': Invalid data') unless JSONSchemer.schema(limit_schema).valid?(self[:limits])
  end
end
