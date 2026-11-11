module Keycloak::Patches::SearchServiceExtension
  private

  def should_skip_inbox_filtering?
    super || account_user.has_permission?(:can_view_all_inboxes)
  end
end
