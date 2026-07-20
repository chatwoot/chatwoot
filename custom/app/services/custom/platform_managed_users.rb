# Fork: platform-managed account_users are INFRASTRUCTURE, not staff.
#
# Provisioning creates two of them per tenant (a service admin holding the
# account's API credential, and the AI identity that posts replies). They are
# already excluded from the agent list and the plan quota
# (Custom::Api::V1::Accounts::AgentsController, Custom::EntitlementService), but
# they are `administrator` role users, so anything reaching for
# `account.administrators` still picks them up.
#
# This is the shared filter for the surfaces where a human is being CHOSEN.
# Deliberately not applied to `Account#administrators` itself: that association
# has ~12 consumers (mailers, ActionCable tokens, automation actions, branding
# jobs) and narrowing it globally would change behavior well outside the vendor
# UI.
module Custom
  module PlatformManagedUsers
    # User ids in this account that are platform-managed infrastructure.
    def self.ids_for(account)
      return [] if account.blank?

      account.account_users.where(platform_managed: true).pluck(:user_id)
    end

    # Drop infrastructure users from a collection of users, preserving order.
    # Returns an Array (callers here already return Arrays via `uniq`).
    def self.reject_from(users, account)
      managed_ids = ids_for(account)
      return users.to_a if managed_ids.empty?

      users.to_a.reject { |user| managed_ids.include?(user.id) }
    end
  end
end
