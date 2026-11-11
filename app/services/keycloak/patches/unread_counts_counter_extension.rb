module Keycloak::Patches::UnreadCountsCounterExtension
  private

  def visible_inbox_ids
    return super unless account_user&.has_permission?(:can_view_all_inboxes)

    @visible_inbox_ids ||= account.inboxes.pluck(:id)
  end
end
