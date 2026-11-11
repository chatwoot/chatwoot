class Keycloak::RoleSyncService
  def initialize(user:, keycloak_roles:)
    @user = user
    @keycloak_roles = Array(keycloak_roles).map(&:to_s)
  end

  def perform
    resolved = Keycloak::PermissionMap.resolve(@keycloak_roles)
    before = visibility_by_account_user
    store_state(resolved)
    account_users.each { |account_user| sync_role(account_user, resolved) }
    invalidate_changed_visibility(before)
  end

  private

  # No mapped Keycloak role leaves the most restricted agent (no extra capabilities).
  def store_state(resolved)
    state = {
      'roles' => @keycloak_roles.map { |role| Keycloak::PermissionMap.normalize(role) },
      'permissions' => resolved ? resolved[:permissions] : []
    }
    @user.update!(custom_attributes: (@user.custom_attributes || {}).merge('keycloak' => state))
  end

  def sync_role(account_user, resolved)
    account_user.update!(role: resolved&.dig(:administrator) ? :administrator : :agent)
  end

  def account_users
    scope = @user.account_users
    account_id = ENV.fetch('KEYCLOAK_ACCOUNT_ID', nil)
    account_id.present? ? scope.where(account_id: account_id) : scope
  end

  def visibility_by_account_user
    account_users.reload.to_h { |account_user| [account_user.id, account_user.has_permission?(:can_view_all_inboxes)] }
  end

  # Capabilities are not account_users columns, so the unread-count cache is invalidated here.
  def invalidate_changed_visibility(before)
    account_users.reload.each do |account_user|
      next if before[account_user.id] == account_user.has_permission?(:can_view_all_inboxes)

      account_user.send(:invalidate_filtered_unread_count_visibility_update)
    end
  end
end
