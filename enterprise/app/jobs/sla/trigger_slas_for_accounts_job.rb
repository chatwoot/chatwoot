class Sla::TriggerSlasForAccountsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.joins(:sla_policies).distinct.find_each do |account|
      Rails.logger.info "Enqueuing ProcessAccountAppliedSlasJob for account #{account.id}"
      Sla::ProcessAccountAppliedSlasJob.perform_later(account)
    end
  end
end
