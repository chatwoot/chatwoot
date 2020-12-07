module Current
  thread_mattr_accessor :user
  thread_mattr_accessor :account
  thread_mattr_accessor :account_user

  def account=(account)
    super
    Time.zone = account.timezone
  end
end
