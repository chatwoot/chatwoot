module Keycloak::Patches::UserExtension
  def assigned_inboxes
    account_user = account_users.find_by(account_id: Current.account.id)
    return Current.account.inboxes if account_user&.has_permission?(:can_view_all_inboxes)

    super
  end
end
