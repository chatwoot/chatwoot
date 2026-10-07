class Account::ShortWindowResolutionSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  SHORT_WINDOW_MINUTES = 10

  def perform
    Account.with_auto_resolve
           .where("(settings ->> 'auto_resolve_after')::int < ?", SHORT_WINDOW_MINUTES)
           .find_each(batch_size: 100) do |account|
      Conversations::ResolutionJob.perform_later(account: account)
    end
  end
end
