class Account::ConversationsResolutionSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.with_auto_resolve.find_each(batch_size: 100) do |account|
      Conversations::ResolutionJob.perform_later(account: account)
    end
  end
end
Account::ConversationsResolutionSchedulerJob.prepend_mod_with('Account::ConversationsResolutionSchedulerJob')
