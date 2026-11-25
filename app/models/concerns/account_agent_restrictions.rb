# Account-level toggles that restrict what basic agents may do. They live in the
# `settings` jsonb rather than `feature_flags` — see the "Account-level toggles"
# section in AGENTS.md — and are exposed to superadmins via `AccountDashboard`.
#
# Include this AFTER the other `store_accessor :settings` calls in `Account`.
# The writers below rely on `super` reaching the store-accessor module, which
# only sits below this concern in the ancestor chain when that module was
# already built by an earlier `store_accessor` call.
module AccountAgentRestrictions
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :hide_agent_unassigned_tab, :hide_agent_all_tab, :disable_agent_message_deletion

    before_validation :enforce_agent_assignee_tabs_constraint
  end

  # The superadmin form posts "1"/"0" and the settings JSON schema only accepts
  # booleans, so every toggle casts its input on the way in.
  def hide_agent_unassigned_tab=(value)
    super(ActiveModel::Type::Boolean.new.cast(value))
  end

  def hide_agent_all_tab=(value)
    super(ActiveModel::Type::Boolean.new.cast(value))
  end

  def disable_agent_message_deletion=(value)
    super(ActiveModel::Type::Boolean.new.cast(value))
  end

  private

  # Hiding "Unassigned" while leaving "All" visible would defeat the toggle:
  # unassigned conversations stay reachable through the "All" tab.
  def enforce_agent_assignee_tabs_constraint
    self.hide_agent_all_tab = true if hide_agent_unassigned_tab
  end
end
