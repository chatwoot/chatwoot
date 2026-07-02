# Serves quota usage to the dashboard on self-hosted installs. Upstream gates
# GET /enterprise/api/v1/accounts/:id/limits behind chatwoot_cloud?; the fork
# opens only that action and extends the response with every quota resource
# in the existing `{ allowed:, consumed: }` shape (docs/fork/ENTITLEMENTS.md).
module Custom::Enterprise::Api::V1::AccountsController
  # `agents` stays on the upstream shape; only new keys are added.
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
    super.merge(quota).merge(agentic_ai_usage_limit)
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
