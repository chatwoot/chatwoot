module Custom::Platform::Api::V1::AccountUsersController
  private

  # Permit the fork's platform-managed flag on the super-admin Platform API so the
  # control plane can mark its automation account_user (the service identity used
  # for provisioning / Application-API calls) as infrastructure. Platform-managed
  # account_users are excluded from the `agents` quota (docs/fork/adr/0002).
  # Human handoff operators (role: agent) are created without the flag and still
  # count toward the tenant's agents limit.
  def account_user_params
    params.permit(:user_id, :role, :platform_managed)
  end
end
