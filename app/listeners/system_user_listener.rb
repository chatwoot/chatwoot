class SystemUserListener < BaseListener
  def account_created(event)
    account = event.data[:account]
    system_users = SystemUser.all
    system_users.find_each do |system_user|
      AccountUser.create!(role: 'system', account: account, user: system_user)
    end
  end

  def system_user_created(event)
    system_user = event.data[:system_user]

    Account.all.find_each do |account|
      AccountUser.create!(role: 'system', account: account, user: system_user)
    end
  end
end
