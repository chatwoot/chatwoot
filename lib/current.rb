module Current
  thread_mattr_accessor :user
  thread_mattr_accessor :account
  thread_mattr_accessor :account_user
  thread_mattr_accessor :executed_by
  thread_mattr_accessor :contact
  thread_mattr_accessor :captain_resolve_reason
  thread_mattr_accessor :captain_action_source
  thread_mattr_accessor :captain_activity_reason

  def self.with_captain_action_source(source)
    previous_source = captain_action_source
    self.captain_action_source = source
    yield
  ensure
    self.captain_action_source = previous_source
  end

  def self.with_captain_activity_reason(reason)
    previous_reason = captain_activity_reason
    self.captain_activity_reason = reason
    yield
  ensure
    self.captain_activity_reason = previous_reason
  end

  def self.reset
    Current.user = nil
    Current.account = nil
    Current.account_user = nil
    Current.executed_by = nil
    Current.contact = nil
    Current.captain_resolve_reason = nil
    Current.captain_action_source = nil
    Current.captain_activity_reason = nil
  end
end
