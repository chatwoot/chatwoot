# Scopes the tenant-facing agents list to real, billable seats by excluding
# platform-managed `account_users` — the control plane's own infrastructure users
# (the automation service admin behind USER_TOKEN and the AI reply identity,
# ADR-0005/0006). Those carry `platform_managed: true` and must never surface in a
# vendor's Agents settings, count against their `agents` plan slot, or be
# editable/deletable by the tenant (deleting the service admin would destroy the
# account's stored API credential).
#
# Overriding the single `agents` finder fixes all three at once, because upstream
# builds `index` (the list), `fetch_agent` (edit/destroy lookup), and
# `available_agent_count` / `can_add_agent?` (the create guard) on top of it:
#   - the list renders only tenant seats,
#   - `agents.find(id)` no longer resolves an infra user → edit/destroy 404,
#   - `usage_limits[:agents] - agents.count` counts only tenant seats, matching
#     `Custom::EntitlementService` (which already filters `platform_managed: false`)
#     and the limits endpoint.
#
# Injected via the canonical `Api::V1::Accounts::AgentsController.prepend_mod_with`
# hook that already ships at the bottom of the upstream controller — no OSS edit,
# zero upstream-merge conflict. `super` inherits whatever the base query becomes on
# future pulls; we only append the filter.
module Custom::Api::V1::Accounts::AgentsController
  private

  def agents
    # NOTE: a distinct ivar is required. `super` memoizes the UNSCOPED relation into
    # `@agents` (`@agents ||= ...` in the base), so reusing `@agents` here would
    # short-circuit on that truthy value and never apply the filter.
    @scoped_agents ||= super.where(account_users: { platform_managed: false })
  end
end
