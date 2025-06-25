class Account::ConversationsResolutionSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.where.not(auto_resolve_duration: nil).all.find_each(batch_size: 100) do |account|
      Conversations::ResolutionJob.perform_later(account: account)
    end
  end
end
