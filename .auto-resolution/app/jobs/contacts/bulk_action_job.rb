class Contacts::BulkActionJob < ApplicationJob
  queue_as :medium

  def perform(account_id, user_id, params)
    account = Account.find(account_id)
    user = User.find(user_id)

    Contacts::BulkActionService.new(
      account: account,
      user: user,
      params: params
    ).perform
  end
end
