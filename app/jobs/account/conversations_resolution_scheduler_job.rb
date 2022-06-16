class Account::ConversationsResolutionSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.where.not(auto_resolve_duration: nil).all.each do |account|
      Conversations::ResolutionJob.perform_later(account: account)
    end
  end
end
