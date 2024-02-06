class Accounts::TriggerSlaJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each do |account|
      Rails.logger.info "Enqueuing AccountSlaJob for account #{account.id}"
      Accounts::SlaResolutionSchedulerJob.perform_later(account)
    end
  end
end
