class UpdateAccountUsersProviderJob < ApplicationJob
  queue_as :default

  def perform(account_id, provider)
    account = Account.find(account_id)
    account.users.find_each(batch_size: 1000) do |user|
      user.update_column(:provider, provider)
    end
  end
end
