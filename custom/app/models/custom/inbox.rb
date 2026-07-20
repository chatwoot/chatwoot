module Custom::Inbox
  def self.prepended(base)
    base.include Custom::Concerns::QuotaGuard
  end

  # Keep infrastructure users out of assignee pickers.
  #
  # Upstream builds this as `inbox members + account.administrators`, and the
  # provisioned service admin IS an administrator — so it surfaced in the
  # conversation assignee dropdown even after the agent LIST was scoped. A vendor
  # could assign a customer conversation to a platform identity no human reads,
  # and the conversation would silently go unanswered.
  #
  # This changes only WHO is offered as an assignee. Assignment mechanics,
  # conversation state, and automation actions are untouched.
  def assignable_agents
    Custom::PlatformManagedUsers.reject_from(super, account)
  end
end
