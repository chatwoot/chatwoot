# Serves quota usage to the dashboard on self-hosted installs. Upstream gates
# GET /enterprise/api/v1/accounts/:id/limits behind chatwoot_cloud?; the fork
# opens only that action and extends the response with every quota resource
# in the existing `{ allowed:, consumed: }` shape (docs/fork/ENTITLEMENTS.md).
module Custom::Enterprise::Api::V1::AccountsController
  # New quota keys served in the `{ allowed:, consumed: }` shape. `agents` is NOT
  # here: it exists on the upstream response already, but its `consumed` is
  # re-derived in `agents_usage_limit` to exclude platform-managed infra (ADR-0005).
  QUOTA_UI_RESOURCES = (%w[inboxes] + Custom::Account::PlanUsageAndLimits::QUOTA_RESOURCES).freeze

  private

  def check_cloud_env
    return if action_name == 'limits'

    super
  end

  # Cloud installs keep the upstream response byte-identical; the fork keys
  # are added only on self-hosted, where the endpoint previously 404'd.
  def default_limits
    return super if ChatwootApp.chatwoot_cloud?

    service = Custom::EntitlementService.new(@account)
    quota = QUOTA_UI_RESOURCES.index_with do |resource|
      usage = service.usage(resource)
      # `allowed: nil` means unlimited, so the UI can skip usage counters
      { 'allowed' => (usage.limit unless usage.limit >= ChatwootApp.max_limit), 'consumed' => usage.current }
    end
    super.merge(quota).merge(agents_usage_limit(service)).merge(agentic_ai_usage_limit)
  end

  # Re-derive the `agents` entry from the entitlement service so `consumed` counts
  # only tenant seats (`platform_managed: false`), matching the create guard and the
  # scoped agents list. Upstream's `agents` key counts every `account_user`, which
  # includes the platform service admin + AI reply user and reads e.g. 2/1 for a
  # 1-seat plan with a single real agent. Overriding it here (self-hosted only; the
  # cloud path early-returns above) keeps the dashboard's `useQuota('agents')` in
  # step with what the backend actually enforces.
  def agents_usage_limit(service)
    usage = service.usage(:agents)
    { 'agents' => { 'allowed' => (usage.limit unless usage.limit >= ChatwootApp.max_limit), 'consumed' => usage.current } }
  end

  # Agentic-AI (automated workflow) usage is enforced by the external NestJS
  # backend, not Chatwoot. The control plane writes the cap into
  # accounts.limits['agentic_ai'] and the running usage into
  # custom_attributes['agentic_ai_usage'] (both via the Platform API); Chatwoot
  # only surfaces it here, display-only, in the existing `{ allowed:, consumed: }`
  # shape so the dashboard banner can warn at the cap. Absent until a cap is
  # provisioned, so accounts without agentic AI get an unchanged response.
  def agentic_ai_usage_limit
    cap = @account[:limits].to_h['agentic_ai']
    return {} if cap.blank?

    { 'agentic_ai' => { 'allowed' => cap.to_i, 'consumed' => @account.custom_attributes.to_h['agentic_ai_usage'].to_i } }
  end
end
