# Dynamic capabilities for account users whose role comes from Keycloak.
# The synced state lives in users.custom_attributes['keycloak'] ({ 'roles' => [...], 'permissions' => [...] }),
# so no database column is added to account_users.
module Keycloak::Patches::AccountUserExtension
  # Upstream permission names the dashboard already understands, granted together with a capability
  UPSTREAM_PERMISSIONS = {
    'can_view_reports' => %w[report_manage],
    'can_import_contacts' => %w[contact_manage],
    'can_export_contacts' => %w[contact_manage]
  }.freeze

  def permissions
    base = super
    return base if administrator? || !keycloak_managed?

    capabilities = effective_capabilities
    Array(base) | capabilities | capabilities.flat_map { |capability| UPSTREAM_PERMISSIONS.fetch(capability, []) }
  end

  # Administrators hold every capability; agents hold the ones synced from their Keycloak role,
  # or the default agent capabilities when no Keycloak role has been synced.
  def has_permission?(permission_key) # rubocop:disable Naming/PredicateName
    administrator? || effective_capabilities.include?(permission_key.to_s)
  end

  def effective_capabilities
    return Array(keycloak_state['permissions']) if keycloak_managed?

    ::Keycloak::PermissionMap.default_agent_capabilities
  end

  def keycloak_managed?
    keycloak_state.key?('permissions')
  end

  private

  def keycloak_state
    state = user&.custom_attributes&.dig('keycloak')
    state.is_a?(Hash) ? state : {}
  end
end
