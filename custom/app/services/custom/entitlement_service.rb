class Custom::EntitlementService
  Result = Struct.new(:resource, :current, :limit, keyword_init: true) do
    def allowed?
      current < limit
    end
  end

  # Platform-managed resources are infrastructure owned by the control plane (the
  # system AI AgentBot, its account webhook, the automation account_user), not
  # tenant-billable seats. They carry `platform_managed: true` and are excluded
  # from every usage count, so a tenant is never charged a plan slot for the
  # platform's own automation. Tenant-created resources (default
  # `platform_managed: false`) count as before. See docs/fork/adr/0002.
  RESOURCE_COUNTERS = {
    agents: ->(account) { account.account_users.where(platform_managed: false).count },
    teams: ->(account) { account.teams.count },
    inboxes: ->(account) { account.inboxes.count },
    agent_bots: ->(account) { account.agent_bots.where(platform_managed: false).count },
    webhooks: ->(account) { account.webhooks.where(platform_managed: false).count },
    labels: ->(account) { account.labels.count },
    custom_attribute_definitions: ->(account) { account.custom_attribute_definitions.count },
    automation_rules: ->(account) { account.automation_rules.count },
    integrations: ->(account) { account.hooks.count }
  }.freeze

  MODEL_RESOURCES = {
    'AccountUser' => :agents,
    'Team' => :teams,
    'Inbox' => :inboxes,
    'AgentBot' => :agent_bots,
    'Webhook' => :webhooks,
    'Label' => :labels,
    'CustomAttributeDefinition' => :custom_attribute_definitions,
    'AutomationRule' => :automation_rules,
    'Integrations::Hook' => :integrations
  }.freeze

  def initialize(account)
    @account = account
  end

  # Side-effect-free usage lookup for read paths (quota UI, serializers).
  def usage(resource)
    resource = resource.to_sym
    Result.new(
      resource: resource,
      current: RESOURCE_COUNTERS.fetch(resource).call(@account),
      limit: limit_for(resource)
    )
  end

  # Enforcement entry point: same result, but denials are logged.
  def check(resource)
    result = usage(resource)
    log_denial(result) unless result.allowed?
    result
  end

  private

  # Per-account limits jsonb → unlimited. Deliberately avoids
  # Account#usage_limits / GlobalConfig here: guards run on every record
  # create, and the GlobalConfig (Redis) lookup both costs a roundtrip per
  # save and breaks upstream specs that mock GlobalConfig strictly. The
  # control plane sets per-tenant limits, so the installation-wide
  # ACCOUNT_<X>_LIMIT fallback is not consulted for quota enforcement.
  def limit_for(resource)
    (@account[:limits].to_h[resource.to_s].presence || ChatwootApp.max_limit).to_i
  end

  def log_denial(result)
    Rails.logger.warn(
      "[QUOTA] denied account_id=#{@account.id} resource=#{result.resource} current=#{result.current} limit=#{result.limit}"
    )
  end
end
