module Current
  thread_mattr_accessor :user
  thread_mattr_accessor :account
  thread_mattr_accessor :account_user

  def account=(account)
    super
    Time.zone = account.timezone
  end

  def self.reset
    Current.user = nil
    Current.account = nil
    Current.account_user = nil
  end
end
